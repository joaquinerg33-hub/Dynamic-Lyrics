import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LyricEntry {
        LyricEntry(date: Date(), title: "Canción", artist: "Artista",
                   previousLine: "Línea anterior", currentLine: "Línea actual",
                   nextLine: "Línea siguiente", hasLyrics: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (LyricEntry) -> Void) {
        if let state = SharedNowPlayingState.load() {
            let entries = LyricTimelineBuilder.buildEntries(from: state, now: Date())
            completion(entries.first ?? placeholder(in: context))
        } else {
            completion(placeholder(in: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LyricEntry>) -> Void) {
        guard let state = SharedNowPlayingState.load() else {
            let entry = LyricEntry(date: Date(), title: "Dynamic Lyrics", artist: "",
                                    previousLine: "", currentLine: "Abre Apple Music para empezar",
                                    nextLine: "", hasLyrics: false)
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300))))
            return
        }

        let entries = LyricTimelineBuilder.buildEntries(from: state, now: Date())
        let reloadDate = entries.last?.date.addingTimeInterval(5) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }
}

struct DynamicLyricsWidgetView: View {
    var entry: LyricEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !entry.previousLine.isEmpty {
                Text(entry.previousLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(entry.currentLine)
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if !entry.nextLine.isEmpty {
                Text(entry.nextLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if !entry.hasLyrics {
                Text(entry.artist)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(10)
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

struct DynamicLyricsWidget: Widget {
    let kind: String = "DynamicLyricsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DynamicLyricsWidgetView(entry: entry)
        }
        .configurationDisplayName("Dynamic Lyrics")
        .description("Muestra la letra sincronizada de lo que suena en Apple Music.")
        .supportedFamilies([.systemSmall])
    }
}
