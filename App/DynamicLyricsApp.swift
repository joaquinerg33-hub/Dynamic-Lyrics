import SwiftUI

@main
struct DynamicLyricsApp: App {
    @StateObject private var nowPlaying = NowPlayingMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(nowPlaying)
                .onAppear {
                    nowPlaying.requestAuthorizationAndStart()
                }
        }
    }
}
