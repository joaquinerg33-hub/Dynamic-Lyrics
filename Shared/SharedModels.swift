import Foundation

/// Nombre del App Group compartido entre la app y el widget.
/// Debe coincidir EXACTAMENTE con el valor en project.yml (ambos targets)
/// y con lo que configures en Xcode/Signing si algún día lo tocas a mano.
enum AppGroup {
    static let id = "group.com.joaquinromero.dynamiclyrics"
}

/// Una línea de letra con su marca de tiempo (en segundos desde el inicio de la canción).
struct LyricLine: Codable, Equatable {
    let time: TimeInterval
    let text: String
}

/// Todo lo que el widget necesita para dibujar el timeline de una canción.
/// Se serializa a JSON y se guarda en UserDefaults(suiteName: AppGroup.id).
struct SharedNowPlayingState: Codable {
    let trackID: String          // identificador único de la canción actual (persistentID)
    let title: String
    let artist: String
    /// Momento real (wall-clock) en el que la canción empezó a sonar desde el segundo 0.
    /// Se calcula como Date() - currentPlaybackTime en el instante en que se guarda.
    let songStartDate: Date
    let isPlaying: Bool
    let lines: [LyricLine]        // vacío si no encontramos letra sincronizada
    let plainLyrics: String?      // fallback sin sincronizar, por si acaso
    let savedAt: Date

    static let storageKey = "sharedNowPlayingState"

    static func load() -> SharedNowPlayingState? {
        guard let defaults = UserDefaults(suiteName: AppGroup.id),
              let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(SharedNowPlayingState.self, from: data)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: AppGroup.id) else { return }
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: SharedNowPlayingState.storageKey)
        }
    }

    static func clear() {
        UserDefaults(suiteName: AppGroup.id)?.removeObject(forKey: storageKey)
    }
}
