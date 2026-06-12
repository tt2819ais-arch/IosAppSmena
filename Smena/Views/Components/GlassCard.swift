import SwiftUI

/// A frosted glass container used across the app.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(scheme == .dark ? 0.18 : 0.6),
                                                Color.white.opacity(0.02)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.4 : 0.08), radius: 18, x: 0, y: 12)
    }
}
