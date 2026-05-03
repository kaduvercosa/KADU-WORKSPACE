document.addEventListener('DOMContentLoaded', () => {
    // UI Elements
    const libraryBtn = document.getElementById('library-btn');
    const eqBtn = document.getElementById('eq-btn');
    const closeLibraryBtn = document.getElementById('close-library-btn');
    const closeEqBtn = document.getElementById('close-eq-btn');

    const libraryView = document.getElementById('library-view');
    const eqView = document.getElementById('eq-view');

    const fileInput = document.getElementById('file-input');
    const playlistEl = document.getElementById('playlist');
    const audioPlayer = document.getElementById('audio-player');

    const trackTitle = document.getElementById('track-title');
    const trackArtist = document.getElementById('track-artist');
    const playPauseBtn = document.getElementById('play-pause-btn');
    const prevBtn = document.getElementById('prev-btn');
    const nextBtn = document.getElementById('next-btn');
    const progressBar = document.getElementById('progress-bar');
    const timeCurrent = document.getElementById('time-current');
    const timeTotal = document.getElementById('time-total');

    let playlist = [];
    let currentTrackIndex = -1;

    // Equalizer Setup (Web Audio API)
    const eqControls = document.getElementById('eq-controls');
    let audioContext;
    let sourceNode;
    let filters = [];
    const frequencies = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000];

    // Generate UI sliders initially (before audio context starts)
    const initEqUI = () => {
        eqControls.innerHTML = '';
        frequencies.forEach((freq, i) => {
            const bandDiv = document.createElement('div');
            bandDiv.className = 'eq-band';

            const slider = document.createElement('input');
            slider.type = 'range';
            slider.className = 'eq-slider';
            slider.min = -12;
            slider.max = 12;
            slider.value = 0;
            slider.orient = 'vertical'; // For browsers that support it

            slider.addEventListener('input', (e) => {
                if (filters[i]) {
                    filters[i].gain.value = parseFloat(e.target.value);
                }
            });

            const label = document.createElement('span');
            label.className = 'eq-label';
            label.textContent = freq >= 1000 ? (freq/1000) + 'k' : freq;

            bandDiv.appendChild(slider);
            bandDiv.appendChild(label);
            eqControls.appendChild(bandDiv);
        });
    };
    initEqUI();

    const initAudioContext = () => {
        if (audioContext) return; // already initialized

        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        sourceNode = audioContext.createMediaElementSource(audioPlayer);

        // Create filters for each frequency band
        frequencies.forEach((freq, i) => {
            const filter = audioContext.createBiquadFilter();
            if (i === 0) {
                filter.type = 'lowshelf';
            } else if (i === frequencies.length - 1) {
                filter.type = 'highshelf';
            } else {
                filter.type = 'peaking';
                filter.Q.value = 1; // Bandwidth
            }
            filter.frequency.value = freq;
            filter.gain.value = 0; // Default flat
            filters.push(filter);
        });

        // Connect the filters in series
        sourceNode.connect(filters[0]);
        for (let i = 0; i < filters.length - 1; i++) {
            filters[i].connect(filters[i + 1]);
        }
        // Connect the last filter to the destination (speakers)
        filters[filters.length - 1].connect(audioContext.destination);
    };

    // Format time (seconds to m:ss)
    const formatTime = (seconds) => {
        if (isNaN(seconds)) return '0:00';
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return `${m}:${s < 10 ? '0' : ''}${s}`;
    };

    // Update UI for current track
    const loadTrack = (index) => {
        if (index < 0 || index >= playlist.length) return;

        const file = playlist[index];
        const url = URL.createObjectURL(file);

        audioPlayer.src = url;
        audioPlayer.load();

        // Basic metadata (we don't have id3-parser here, so we use filename)
        let name = file.name.replace(/\.[^/.]+$/, ""); // Remove extension
        trackTitle.textContent = name;
        trackArtist.textContent = 'Local File';

        // Update playlist UI
        const items = playlistEl.querySelectorAll('li');
        items.forEach((item, i) => {
            if (i === index) item.classList.add('active');
            else item.classList.remove('active');
        });

        currentTrackIndex = index;
    };

    const playTrack = () => {
        if (currentTrackIndex === -1 && playlist.length > 0) {
            loadTrack(0);
        }
        if (audioPlayer.src) {
            // Need user interaction to initialize AudioContext on some browsers
            initAudioContext();
            if (audioContext && audioContext.state === 'suspended') {
                audioContext.resume();
            }
            audioPlayer.play();
            playPauseBtn.textContent = '⏸';
        }
    };

    const pauseTrack = () => {
        audioPlayer.pause();
        playPauseBtn.textContent = '▶';
    };

    const togglePlayPause = () => {
        if (audioPlayer.paused) {
            playTrack();
        } else {
            pauseTrack();
        }
    };

    const nextTrack = () => {
        if (playlist.length === 0) return;
        let nextIndex = currentTrackIndex + 1;
        if (nextIndex >= playlist.length) nextIndex = 0; // loop
        loadTrack(nextIndex);
        playTrack();
    };

    const prevTrack = () => {
        if (playlist.length === 0) return;
        let prevIndex = currentTrackIndex - 1;
        if (prevIndex < 0) prevIndex = playlist.length - 1; // loop
        loadTrack(prevIndex);
        playTrack();
    };

    // UI Event Listeners
    libraryBtn.addEventListener('click', () => {
        libraryView.classList.remove('hidden');
    });

    closeLibraryBtn.addEventListener('click', () => {
        libraryView.classList.add('hidden');
    });

    eqBtn.addEventListener('click', () => {
        eqView.classList.remove('hidden');
    });

    closeEqBtn.addEventListener('click', () => {
        eqView.classList.add('hidden');
    });

    // File handling
    fileInput.addEventListener('change', (e) => {
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        playlist = playlist.concat(files);

        // Update playlist UI
        playlistEl.innerHTML = '';
        playlist.forEach((file, index) => {
            const li = document.createElement('li');
            li.textContent = file.name;
            li.addEventListener('click', () => {
                loadTrack(index);
                playTrack();
                libraryView.classList.add('hidden'); // Close library on select
            });
            playlistEl.appendChild(li);
        });

        // Load first track if nothing is playing
        if (currentTrackIndex === -1) {
            loadTrack(0);
        }
    });

    // Transport controls
    playPauseBtn.addEventListener('click', togglePlayPause);
    nextBtn.addEventListener('click', nextTrack);
    prevBtn.addEventListener('click', prevTrack);

    // Audio player events
    audioPlayer.addEventListener('timeupdate', () => {
        const currentTime = audioPlayer.currentTime;
        const duration = audioPlayer.duration;

        timeCurrent.textContent = formatTime(currentTime);
        if (duration) {
            timeTotal.textContent = formatTime(duration);
            progressBar.value = (currentTime / duration) * 100;
        }
    });

    audioPlayer.addEventListener('ended', nextTrack);

    progressBar.addEventListener('input', (e) => {
        const duration = audioPlayer.duration;
        if (duration) {
            audioPlayer.currentTime = (e.target.value / 100) * duration;
        }
    });

    console.log('Playback logic attached');
});
