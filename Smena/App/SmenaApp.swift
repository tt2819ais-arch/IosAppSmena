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
                    .environment(\.appearance, store.settings.appearance)
                    .tint(store.accent.primary)

                if showLaunch {
                    LaunchView(accent: store.accent, appearance: store.settings.appearance)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(store.settings.appearance.colorScheme)
            .onAppear {
                // Elegant launch animation runs ~1.0s, then fades out.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.45)) { showLaunch = false }
                }
            }
        }
    }
}
