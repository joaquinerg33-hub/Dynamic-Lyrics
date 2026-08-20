import WidgetKit
import Foundation

struct LyricEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let previousLine: String
    let currentLine: String
    let nextLine: String
    let hasLyrics: Bool
}

/// Construye la lista de entradas futuras del timeline a partir del estado compartido
/// guardado por la app. Esta es la pieza clave que logra el efecto "dinámico": en vez
/// de refrescar el widget constantemente (WidgetKit no lo permite), le damos de una vez
/// todas las líneas con su fecha real de aparición, y el sistema las va mostrando solo
/// en el momento correcto.
enum LyricTimelineBuilder {

    static func buildEntries(from state: SharedNowPlayingState, now: Date) -> [LyricEntry] {
        guard !state.lines.isEmpty else {
            return [
                LyricEntry(
                    date: now,
                    title: state.title,
                    artist: state.artist,
                    previousLine: "",
                    currentLine: state.plainLyrics ?? "Letra no disponible",
                    nextLine: "",
                    hasLyrics: state.plainLyrics != nil
                )
            ]
        }

        if !state.isPlaying {
            let elapsed = state.savedAt.timeIntervalSince(state.songStartDate)
            let idx = currentIndex(for: elapsed, in: state.lines)
            return [makeEntry(at: now, index: idx, state: state)]
        }

        var entries: [LyricEntry] = []
        let elapsedNow = now.timeIntervalSince(state.songStartDate)
        let startIdx = currentIndex(for: elapsedNow, in: state.lines)
        entries.append(makeEntry(at: now, index: startIdx, state: state))

        var idx = startIdx + 1
        while idx < state.lines.count {
            let entryDate = state.songStartDate.addingTimeInterval(state.lines[idx].time)
            if entryDate > now {
                entries.append(makeEntry(at: entryDate, index: idx, state: state))
            }
            idx += 1
        }
        return entries
    }

    private static func currentIndex(for elapsed: TimeInterval, in lines: [LyricLine]) -> Int {
        var idx = 0
        for (i, line) in lines.enumerated() {
            if line.time <= elapsed { idx = i } else { break }
        }
        return idx
    }

    private static func makeEntry(at date: Date, index: Int, state: SharedNowPlayingState) -> LyricEntry {
        let prev = index > 0 ? state.lines[index - 1].text : ""
        let curr = state.lines[index].text
        let next = index + 1 < state.lines.count ? state.lines[index + 1].text : ""
        return LyricEntry(date: date, title: state.title, artist: state.artist, previousLine: prev, currentLine: curr, nextLine: next, hasLyrics: true)
    }
}
