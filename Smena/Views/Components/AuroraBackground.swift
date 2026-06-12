import SwiftUI

/// Animated ambient background: soft drifting blurred orbs in the accent
/// colors over an adaptive base. Works in both light and dark mode.
struct AuroraBackground: View {
    var accent: AccentTone
    @Environment(\.colorScheme) private var scheme
    @State private var animate = false

    var body: some View {
        ZStack {
            baseColor.ignoresSafeArea()

            orb(accent.primary, size: 360)
                .offset(x: animate ? -110 : -70, y: animate ? -220 : -260)
            orb(accent.secondary, size: 300)
                .offset(x: animate ? 130 : 90, y: animate ? -90 : -50)
            orb(accent.primary.opacity(0.8), size: 320)
                .offset(x: animate ? 90 : 140, y: animate ? 320 : 360)
            orb(accent.secondary.opacity(0.7), size: 260)
                .offset(x: animate ? -130 : -90, y: animate ? 240 : 280)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private var baseColor: Color {
        scheme == .dark ? Color(hex: 0x0A0A12) : Color(hex: 0xF4F3FA)
    }

    private func orb(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(scheme == .dark ? 0.55 : 0.35)
            .blur(radius: 90)
    }
}
