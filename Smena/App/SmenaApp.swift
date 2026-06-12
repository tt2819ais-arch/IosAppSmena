import SwiftUI

@main
struct SmenaApp: App {
    @StateObject private var store = AppStore()
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                    .environmentObject(store)
                    .tint(store.accent.primary)

                if showLaunch {
                    LaunchView(accent: store.accent)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(store.settings.theme.colorScheme)
            .onAppear {
                // Keep the launch animation on screen ~0.6s, then fade out.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.4)) { showLaunch = false }
                }
            }
        }
    }
}
