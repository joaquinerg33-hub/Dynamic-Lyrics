import Foundation
import MediaPlayer
import WidgetKit
import Combine

@MainActor
final class NowPlayingMonitor: ObservableObject {
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var currentTitle: String = "Nada sonando"
    @Published var currentArtist: String = ""
    @Published var currentLyricPreview: String = ""
    @Published var isFetchingLyrics: Bool = false

    private let player = MPMusicPlayerController.systemMusicPlayer
    private var lastTrackID: MPMediaEntityPersistentID?
    private var fetchTask: Task<Void, Never>?

    static let widgetKind = "DynamicLyricsWidget"

    func requestAuthorizationAndStart() {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.startObserving()
                }
            }
        }
    }

    private func startObserving() {
        player.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            self, selector: #selector(nowPlayingChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player
        )

        // Primer chequeo inmediato por si ya hay algo sonando.
        handleCurrentItem()
    }

    @objc private func nowPlayingChanged() {
        Task { @MainActor in handleCurrentItem() }
    }

    @objc private func playbackStateChanged() {
        Task { @MainActor in
            // Si el usuario pausa/reanuda, recalculamos el punto de referencia de tiempo
            // para que el timeline del widget siga sincronizado.
            guard let item = player.nowPlayingItem else { return }
            persistState(for: item, isPlaying: player.playbackState == .playing, lines: lastLines, plain: lastPlain)
        }
    }

    private var lastLines: [LyricLine] = []
    private var lastPlain: String?

    private func handleCurrentItem() {
        guard let item = player.nowPlayingItem else {
            currentTitle = "Nada sonando"
            currentArtist = ""
            currentLyricPreview = ""
            SharedNowPlayingState.clear()
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
            return
        }

        currentTitle = item.title ?? "Sin título"
        currentArtist = item.artist ?? ""

        let trackID = item.persistentID
        guard trackID != lastTrackID else { return }
        lastTrackID = trackID

        fetchTask?.cancel()
        isFetchingLyrics = true
        currentLyricPreview = "Buscando letra…"

        fetchTask = Task { [weak self] in
            guard let self else { return }
            let duration = item.playbackDuration > 0 ? Int(item.playbackDuration) : nil
            let result = await LyricsFetcher.fetch(
                title: item.title ?? "",
                artist: item.artist ?? "",
                album: item.albumTitle,
                durationSeconds: duration
            )
            guard !Task.isCancelled else { return }

            let lines = result?.lines ?? []
            let plain = result?.plain

            self.lastLines = lines
            self.lastPlain = plain
            self.isFetchingLyrics = false
            self.currentLyricPreview = lines.first?.text ?? (plain != nil ? "Letra sin sincronizar disponible" : "Letra no encontrada")

            self.persistState(for: item, isPlaying: self.player.playbackState == .playing, lines: lines, plain: plain)
        }
    }

    private func persistState(for item: MPMediaItem, isPlaying: Bool, lines: [LyricLine], plain: String?) {
        let elapsed = player.currentPlaybackTime
        let songStart = Date().addingTimeInterval(-elapsed)

        let state = SharedNowPlayingState(
            trackID: String(item.persistentID),
            title: item.title ?? "",
            artist: item.artist ?? "",
            songStartDate: songStart,
            isPlaying: isPlaying,
            lines: lines,
            plainLyrics: plain,
            savedAt: Date()
        )
        state.save()
        WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
    }
}
