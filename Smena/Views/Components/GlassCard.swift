import SwiftUI

/// A surface container used across the app. Adapts to the selected appearance:
/// frosted material on the animated aurora, calm solid fills on the plain
/// white / black modes (cheaper to render and visually quieter).
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: () -> Content
    @Environment(\.appearance) private var appearance

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(appearance.cardBorder, lineWidth: 1)
            )
            .shadow(color: appearance.cardShadow, radius: 14, x: 0, y: 8)
    }

    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if appearance.usesMaterial {
            shape.fill(.ultraThinMaterial)
                .overlay(shape.fill(appearance.cardFill))
        } else {
            shape.fill(appearance.cardFill)
        }
    }
}
