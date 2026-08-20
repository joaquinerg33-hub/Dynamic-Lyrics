import SwiftUI
import MediaPlayer

struct ContentView: View {
    @EnvironmentObject private var nowPlaying: NowPlayingMonitor

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "car.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)

                Text("Dynamic Lyrics")
                    .font(.title.bold())

                statusCard

                VStack(alignment: .leading, spacing: 6) {
                    Text(nowPlaying.currentTitle)
                        .font(.headline)
                    Text(nowPlaying.currentArtist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if nowPlaying.isFetchingLyrics {
                        ProgressView().padding(.top, 4)
                    } else if !nowPlaying.currentLyricPreview.isEmpty {
                        Text(nowPlaying.currentLyricPreview)
                            .font(.body.italic())
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Spacer()

                Text("Para ver la letra en tu auto: Ajustes → General → CarPlay → tu vehículo → Widgets → agrega \"Dynamic Lyrics\".")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        switch nowPlaying.authorizationStatus {
        case .authorized:
            Label("Conectado a Apple Music", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .denied, .restricted:
            Label("Sin permiso para leer Apple Music. Actívalo en Ajustes → Privacidad → Música.", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        default:
            Label("Solicitando acceso a Apple Music…", systemImage: "hourglass")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView().environmentObject(NowPlayingMonitor())
}
