import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Models

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var title: String
    var artist: String
    var album: String
    var artworkData: Data?
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    @Published var accentColor: Color = .black

    let availableColors: [Color] = [
        .black, .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo, .gray
    ]
}

// MARK: - Audio Manager

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTrack: Track?
    @Published var tracks: [Track] = []
    @Published var progress: Double = 0.0
    @Published var duration: Double = 0.0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func addTracks(urls: [URL]) {
        Task { @MainActor in
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }

                let tempDir = FileManager.default.temporaryDirectory
                let destURL = tempDir.appendingPathComponent(url.lastPathComponent)

                do {
                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.copyItem(at: url, to: destURL)

                    url.stopAccessingSecurityScopedResource()

                    let asset = AVURLAsset(url: destURL)
                    var title = destURL.deletingPathExtension().lastPathComponent
                    var artist = "Unknown Artist"
                    var album = "Unknown Album"
                    var artworkData: Data? = nil

                    do {
                        let metadata = try await asset.load(.commonMetadata)
                        for item in metadata {
                            if let commonKey = item.commonKey {
                                switch commonKey {
                                case .commonKeyTitle:
                                    if let value = try? await item.load(.stringValue) {
                                        title = value
                                    }
                                case .commonKeyArtist:
                                    if let value = try? await item.load(.stringValue) {
                                        artist = value
                                    }
                                case .commonKeyAlbumName:
                                    if let value = try? await item.load(.stringValue) {
                                        album = value
                                    }
                                case .commonKeyArtwork:
                                    if let value = try? await item.load(.dataValue) {
                                        artworkData = value
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    } catch {
                        print("Failed to load metadata: \(error.localizedDescription)")
                    }

                    let track = Track(url: destURL, title: title, artist: artist, album: album, artworkData: artworkData)
                    if !self.tracks.contains(where: { $0.url == track.url }) {
                        self.tracks.append(track)
                    }
                } catch {
                    print("Failed to copy or read file: \(error.localizedDescription)")
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
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
            skipForward()
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

// MARK: - Formatters

func formatTime(_ time: Double) -> String {
    guard !time.isNaN && !time.isInfinite else { return "0:00" }
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// MARK: - Views

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) var dismiss

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

                // Artwork
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

                // Metadata
                VStack(spacing: 8) {
                    Text(audioManager.currentTrack?.title ?? "Not Playing")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .lineLimit(1)

                    Text(audioManager.currentTrack?.artist ?? "Artist")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
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
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text(audioManager.currentTrack?.artist ?? "Artist")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
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
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)

                if audioManager.tracks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Your library is empty.")
                            .font(.system(.title3, design: .rounded).weight(.medium))
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text(track.artist)
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
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
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
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
            }
        }
    }
}

// MARK: - Main Content View

public struct ContentView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    @StateObject private var settings = SettingsManager()
    @State private var isPlayerExpanded = false

    public init() {}

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
    }
}
