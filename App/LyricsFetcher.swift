import Foundation

/// Obtiene letras sincronizadas desde LRCLIB (https://lrclib.net), una base de datos
/// abierta y gratuita de letras en formato LRC. No requiere API key.
/// Si la canción no está en LRCLIB, no hay letra sincronizada disponible (limitación
/// conocida: puede fallar con canciones muy nuevas o poco populares).
enum LyricsFetcher {

    struct LRCLIBResult: Decodable {
        let syncedLyrics: String?
        let plainLyrics: String?
    }

    static func fetch(title: String, artist: String, album: String?, durationSeconds: Int?) async -> (lines: [LyricLine], plain: String?)? {
        // 1) Intento exacto vía /api/get
        if let result = await getExact(title: title, artist: artist, album: album, duration: durationSeconds) {
            return parse(result)
        }
        // 2) Fallback: búsqueda difusa vía /api/search
        if let result = await searchFallback(title: title, artist: artist) {
            return parse(result)
        }
        return nil
    }

    private static func parse(_ result: LRCLIBResult) -> (lines: [LyricLine], plain: String?) {
        guard let synced = result.syncedLyrics, !synced.isEmpty else {
            return ([], result.plainLyrics)
        }
        return (LRCParser.parse(synced), result.plainLyrics)
    }

    private static func getExact(title: String, artist: String, album: String?, duration: Int?) async -> LRCLIBResult? {
        var components = URLComponents(string: "https://lrclib.net/api/get")!
        var items = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        if let album { items.append(URLQueryItem(name: "album_name", value: album)) }
        if let duration { items.append(URLQueryItem(name: "duration", value: String(duration))) }
        components.queryItems = items

        guard let url = components.url else { return nil }
        return try? await fetchJSON(url: url)
    }

    private static func searchFallback(title: String, artist: String) async -> LRCLIBResult? {
        var components = URLComponents(string: "https://lrclib.net/api/search")!
        components.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
        ]
        guard let url = components.url else { return nil }

        struct SearchResponseItem: Decodable {
            let syncedLyrics: String?
            let plainLyrics: String?
        }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let items = try? JSONDecoder().decode([SearchResponseItem].self, from: data),
              let first = items.first(where: { $0.syncedLyrics != nil }) ?? items.first
        else { return nil }
        return LRCLIBResult(syncedLyrics: first.syncedLyrics, plainLyrics: first.plainLyrics)
    }

    private static func fetchJSON(url: URL) async throws -> LRCLIBResult {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(LRCLIBResult.self, from: data)
    }
}

/// Parser simple de formato LRC: líneas tipo "[01:23.45]Texto de la letra".
enum LRCParser {
    static func parse(_ raw: String) -> [LyricLine] {
        var result: [LyricLine] = []
        let timeTagRegex = try! NSRegularExpression(pattern: #"\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]"#)

        for rawLine in raw.split(separator: "\n") {
            let line = String(rawLine)
            let range = NSRange(line.startIndex..., in: line)
            let matches = timeTagRegex.matches(in: line, range: range)
            guard !matches.isEmpty else { continue }

            // El texto es lo que queda después de quitar todas las etiquetas [mm:ss.xx]
            let text = timeTagRegex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
                .trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            for match in matches {
                guard let minRange = Range(match.range(at: 1), in: line),
                      let secRange = Range(match.range(at: 2), in: line) else { continue }
                let minutes = Double(line[minRange]) ?? 0
                let seconds = Double(line[secRange]) ?? 0
                var fraction = 0.0
                if match.range(at: 3).location != NSNotFound, let fracRange = Range(match.range(at: 3), in: line) {
                    let fracString = String(line[fracRange])
                    let padded = fracString.count == 1 ? fracString + "00" : fracString
                    fraction = (Double(padded) ?? 0) / 1000.0
                }
                let time = minutes * 60 + seconds + fraction
                result.append(LyricLine(time: time, text: text))
            }
        }
        return result.sorted { $0.time < $1.time }
    }
}
