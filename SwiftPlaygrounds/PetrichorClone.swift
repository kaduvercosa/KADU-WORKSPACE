import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import MediaPlayer

// MARK: - Models

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var title: String
    var artist: String
    var album: String
    var artworkData: Data?
    var lyrics: [LyricLine]?
}

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: Double
    let text: String
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    @Published var accentColor: Color = .black
    @Published var useGlassButtons: Bool = false
    @Published var fontDesign: Font.Design = .rounded
    @Published var autoPlayNext: Bool = true
    @Published var showArtworkInLibrary: Bool = true

    let availableColors: [Color] = [
        .black, .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo, .gray
    ]

    let availableFonts: [(String, Font.Design)] = [
        ("Default", .default),
        ("Rounded", .rounded),
        ("Serif", .serif),
        ("Monospaced", .monospaced)
    ]
}

// MARK: - Audio Manager

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTrack: Track?
    @Published var tracks: [Track] = []
    @Published var progress: Double = 0.0
    @Published var duration: Double = 0.0

    var settings: SettingsManager? // To access autoPlayNext

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func addTracks(urls: [URL]) {
        Task { @MainActor in
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }

                var filesToProcess: [URL] = []
                var isDirectory: ObjCBool = false

                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        let keys: [URLResourceKey] = [.isDirectoryKey]
                        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) {
                            for case let fileURL as URL in enumerator {
                                let ext = fileURL.pathExtension.lowercased()
                                if ["mp3", "m4a", "wav", "flac", "aac", "aiff", "alac"].contains(ext) {
                                    filesToProcess.append(fileURL)
                                }
                            }
                        }
                    } else {
                        filesToProcess.append(url)
                    }
                }

                for fileURL in filesToProcess {
                    let tempDir = FileManager.default.temporaryDirectory
                    let destURL = tempDir.appendingPathComponent(UUID().uuidString + "-" + fileURL.lastPathComponent)

                    do {
                        try FileManager.default.copyItem(at: fileURL, to: destURL)

                        // Check for LRC
                        let lrcURL = fileURL.deletingPathExtension().appendingPathExtension("lrc")
                        var parsedLyrics: [LyricLine]? = nil
                        if FileManager.default.fileExists(atPath: lrcURL.path) {
                            if let lrcContent = try? String(contentsOf: lrcURL, encoding: .utf8) {
                                parsedLyrics = parseLRC(lrcContent)
                            }
                        }

                        let asset = AVURLAsset(url: destURL)
                        var title = destURL.deletingPathExtension().lastPathComponent
                        var artist = "Unknown Artist"
                        var album = "Unknown Album"
                        var artworkData: Data? = nil

                        do {
                            var allMetadata: [AVMetadataItem] = try await asset.load(.commonMetadata)
                            let formats = try await asset.load(.availableMetadataFormats)
                            for format in formats {
                                let formatMetadata = try await asset.loadMetadata(for: format)
                                allMetadata.append(contentsOf: formatMetadata)
                            }

                            for item in allMetadata {
                                if let commonKey = item.commonKey {
                                    switch commonKey {
                                    case .commonKeyTitle:
                                        if let value = try? await item.load(.value) as? String { title = value }
                                    case .commonKeyArtist:
                                        if let value = try? await item.load(.value) as? String { artist = value }
                                    case .commonKeyAlbumName:
                                        if let value = try? await item.load(.value) as? String { album = value }
                                    case .commonKeyArtwork:
                                        if let value = try? await item.load(.value) as? Data { artworkData = value }
                                    default:
                                        break
                                    }
                                }
                            }
                        } catch {
                            print("Failed to load metadata: \(error.localizedDescription)")
                        }

                        let track = Track(url: destURL, title: title, artist: artist, album: album, artworkData: artworkData, lyrics: parsedLyrics)
                        // Prevent duplicates by checking title and artist instead of temp URL
                        if !self.tracks.contains(where: { $0.title == track.title && $0.artist == track.artist && $0.album == track.album }) {
                            self.tracks.append(track)
                        }
                    } catch {
                        print("Failed to copy or read file: \(error.localizedDescription)")
                    }
                }

                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    func clearLibrary() {
        stopTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTrack = nil
        tracks.removeAll()
        progress = 0.0
    }

    override init() {
        super.init()
        setupRemoteTransportControls()
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.playPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.playPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.skipForward()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.skipBackward()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album

        if let artworkData = track.artworkData, let image = UIImage(data: artworkData) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer?.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func playTrack(_ track: Track) {
        currentTrack = track

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: track.url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            duration = audioPlayer?.duration ?? 0.0
            isPlaying = true

            startTimer()
            updateNowPlaying()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    func playPause() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
        updateNowPlaying()
    }

    func skipForward() {
        guard !tracks.isEmpty else { return }
        guard let currentTrack = currentTrack, let currentIndex = tracks.firstIndex(of: currentTrack) else {
            playTrack(tracks.first!)
            return
        }
        let nextIndex = (currentIndex + 1) % tracks.count
        playTrack(tracks[nextIndex])
    }

    func skipBackward() {
        guard !tracks.isEmpty else { return }
        guard let currentTrack = currentTrack, let currentIndex = tracks.firstIndex(of: currentTrack) else {
            playTrack(tracks.last!)
            return
        }
        let prevIndex = (currentIndex - 1 + tracks.count) % tracks.count
        playTrack(tracks[prevIndex])
    }

    func seek(to time: Double) {
        audioPlayer?.currentTime = time
        progress = time
        updateNowPlaying()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.progress = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            if settings?.autoPlayNext ?? true {
                skipForward()
            } else {
                isPlaying = false
                stopTimer()
                progress = 0.0
            }
        }
    }
}

// MARK: - App Entry Point

@main
struct PetrichorCloneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Formatters & Utilities

func parseLRC(_ content: String) -> [LyricLine] {
    var lines: [LyricLine] = []
    let pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2})\\](.*)"

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return lines }

    let nsString = content as NSString
    let results = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

    for match in results {
        if match.numberOfRanges == 5 {
            let minStr = nsString.substring(with: match.range(at: 1))
            let secStr = nsString.substring(with: match.range(at: 2))
            let msStr = nsString.substring(with: match.range(at: 3))
            let text = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)

            if let min = Double(minStr), let sec = Double(secStr), let ms = Double(msStr) {
                let time = (min * 60.0) + sec + (ms / 100.0)
                lines.append(LyricLine(time: time, text: text))
            }
        }
    }

    return lines.sorted { $0.time < $1.time }
}

func formatTime(_ time: Double) -> String {
    guard !time.isNaN && !time.isInfinite else { return "0:00" }
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// MARK: - Views

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audioManager: AudioPlayerManager
    @Environment(\.dismiss) var dismiss
    @State private var showingClearConfirm = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance").font(.subheadline.weight(.medium))) {
                    Picker("Accent Color", selection: $settings.accentColor) {
                        ForEach(settings.availableColors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 20, height: 20)
                                Text(color.description.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Picker("Font Design", selection: $settings.fontDesign) {
                        ForEach(settings.availableFonts, id: \.1) { font in
                            Text(font.0).tag(font.1)
                        }
                    }

                    Toggle("Glass Buttons", isOn: $settings.useGlassButtons)
                        .tint(settings.accentColor)

                    Toggle("Show Artwork in Library", isOn: $settings.showArtworkInLibrary)
                        .tint(settings.accentColor)
                }

                Section(header: Text("Playback").font(.subheadline.weight(.medium))) {
                    Toggle("Auto-Play Next Track", isOn: $settings.autoPlayNext)
                        .tint(settings.accentColor)
                }

                Section(header: Text("Library").font(.subheadline.weight(.medium))) {
                    Button(role: .destructive, action: {
                        showingClearConfirm = true
                    }) {
                        Text("Clear Library")
                    }
                    .confirmationDialog("Are you sure you want to clear the library?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                        Button("Clear All", role: .destructive) {
                            audioManager.clearLibrary()
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(settings.accentColor)
                }
            }
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var settings: SettingsManager
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: isExpanded ? 30 : 0) {
            if isExpanded {
                // Drag indicator
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                // Artwork OR Lyrics
                TabView {
                    // Artwork Tab
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

                        if let track = audioManager.currentTrack, let data = track.artworkData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 80, weight: .ultraLight))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // Lyrics Tab
                    if let track = audioManager.currentTrack, let lyrics = track.lyrics, !lyrics.isEmpty {
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 24) {
                                    ForEach(lyrics.indices, id: \.self) { index in
                                        let line = lyrics[index]
                                        let isCurrent = (audioManager.progress >= line.time) &&
                                                        (index == lyrics.count - 1 || audioManager.progress < lyrics[index + 1].time)

                                        Text(line.text)
                                            .font(.system(size: isCurrent ? 26 : 22, weight: isCurrent ? .bold : .medium, design: settings.fontDesign))
                                            .foregroundColor(isCurrent ? settings.accentColor : .secondary)
                                            .multilineTextAlignment(.center)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
                                            .id(line.id)
                                            .onChange(of: isCurrent) { currentlyActive in
                                                if currentlyActive {
                                                    withAnimation(.easeInOut) {
                                                        proxy.scrollTo(line.id, anchor: .center)
                                                    }
                                                }
                                            }
                                    }
                                }
                                .padding(.vertical, 100)
                                .padding(.horizontal, 20)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No lyrics available")
                                .font(.system(size: 18, weight: .medium, design: settings.fontDesign))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                // Metadata
                VStack(spacing: 8) {
                    Text(audioManager.currentTrack?.title ?? "Not Playing")
                        .font(.system(size: 24, weight: .bold, design: settings.fontDesign))
                        .lineLimit(1)

                    Text(audioManager.currentTrack?.artist ?? "Artist")
                        .font(.system(size: 18, weight: .medium, design: settings.fontDesign))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal)

                // Progress Bar
                VStack(spacing: 8) {
                    Slider(value: Binding(get: {
                        audioManager.progress
                    }, set: { newValue in
                        audioManager.seek(to: newValue)
                    }), in: 0...max(0.1, audioManager.duration))
                    .accentColor(settings.accentColor)

                    HStack {
                        Text(formatTime(audioManager.progress))
                        Spacer()
                        Text(formatTime(audioManager.duration))
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)

                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        audioManager.skipBackward()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }

                    Button(action: {
                        audioManager.playPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: 70, height: 70)
                                .shadow(color: settings.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)

                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        audioManager.skipForward()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.bottom, 30)

                Spacer(minLength: 0)
            } else {
                // Mini Player
                HStack {
                    // Small Artwork
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 48, height: 48)

                        if let track = audioManager.currentTrack, let data = track.artworkData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            Image(systemName: "music.note")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 2) {
                        Text(audioManager.currentTrack?.title ?? "Not Playing")
                            .font(.system(size: 16, weight: .semibold, design: settings.fontDesign))
                            .lineLimit(1)
                        Text(audioManager.currentTrack?.artist ?? "Artist")
                            .font(.system(size: 14, weight: .regular, design: settings.fontDesign))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Mini Controls
                    Button(action: {
                        audioManager.playPause()
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    .padding(.trailing, 8)

                    Button(action: {
                        audioManager.skipForward()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 40 : 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .padding(.horizontal, isExpanded ? 0 : 16)
        .padding(.bottom, isExpanded ? 0 : 16)
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 50 && isExpanded {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }
            }
        )
    }
}

struct LibraryView: View {
    @EnvironmentObject var audioManager: AudioPlayerManager
    @EnvironmentObject var settings: SettingsManager
    @State private var showingFilePicker = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                if audioManager.tracks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Your library is empty.")
                            .font(.system(.title3, design: settings.fontDesign).weight(.medium))
                            .foregroundColor(.secondary)
                        Button(action: { showingFilePicker = true }) {
                            Text("Add Music")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(settings.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    List {
                        ForEach(audioManager.tracks) { track in
                            Button(action: {
                                audioManager.playTrack(track)
                            }) {
                                HStack(spacing: 16) {
                                    if settings.showArtworkInLibrary {
                                        // Thumbnail
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color(UIColor.secondarySystemBackground))
                                                .frame(width: 50, height: 50)

                                            if let data = track.artworkData, let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            } else {
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }

                                            if audioManager.currentTrack == track && audioManager.isPlaying {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(settings.accentColor)
                                                    .font(.system(size: 20, weight: .bold))
                                                    .shadow(color: .black.opacity(0.5), radius: 2)
                                            }
                                        }
                                    } else {
                                        if audioManager.currentTrack == track && audioManager.isPlaying {
                                            Image(systemName: "waveform")
                                                .foregroundColor(settings.accentColor)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.system(size: 16, weight: .semibold, design: settings.fontDesign))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .font(.system(size: 14, weight: .regular, design: settings.fontDesign))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            audioManager.tracks.remove(atOffsets: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(settings.accentColor)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilePicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(settings.accentColor)
                            .font(.title2)
                    }
                }
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.audio, .folder], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    audioManager.addTracks(urls: urls)
                case .failure(let error):
                    print("Failed to select files: \(error.localizedDescription)")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
                    .environmentObject(audioManager)
            }
        }
    }
}

// MARK: - Main Content View

public struct ContentView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    @StateObject private var settings = SettingsManager()
    @State private var isPlayerExpanded = false

    public init() {
        // Link settings to audioManager initially doesn't work here due to StateObject,
        // we handle it in onAppear.
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Library background/list
            LibraryView()
                .environmentObject(audioManager)
                .environmentObject(settings)
                .padding(.bottom, audioManager.currentTrack != nil ? 80 : 0) // Leave space for mini player

            // Mini Player or Full Player Overlay
            if audioManager.currentTrack != nil {
                PlayerView(isExpanded: $isPlayerExpanded)
                    .environmentObject(audioManager)
                    .environmentObject(settings)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPlayerExpanded)
                    .edgesIgnoringSafeArea(isPlayerExpanded ? .all : .bottom)
            }
        }
        .onAppear {
            audioManager.settings = settings
        }
    }
}
