import SwiftUI

/// Elegant ~1s launch animation: a thin ring draws itself while a clock hand
/// sweeps into place and a soft glow blooms, then the wordmark settles in.
/// Theme-aware so it looks right on light, dark and aurora modes.
struct LaunchView: View {
    var accent: AccentTone
    var appearance: Appearance

    @State private var ringTrim: CGFloat = 0
    @State private var handAngle: Double = -90
    @State private var dotIn = false
    @State private var glow = false
    @State private var wordIn = false

    private var markColor: Color {
        appearance.colorScheme == .light ? Color(hex: 0x14141A) : .white
    }

    var body: some View {
        ZStack {
            appearance.baseColor.ignoresSafeArea()

            // Soft accent bloom (radial gradient — no blur, cheap).
            RadialGradient(colors: [accent.primary.opacity(glow ? 0.30 : 0.0), .clear],
                           center: .center, startRadius: 0, endRadius: 260)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.8), value: glow)

            VStack(spacing: 26) {
                ZStack {
                    // Drawing ring.
                    Circle()
                        .trim(from: 0, to: ringTrim)
                        .stroke(accent.gradient,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 96, height: 96)

                    // Sweeping clock hand.
                    Capsule()
                        .fill(markColor)
                        .frame(width: 4, height: 30)
                        .offset(y: -15)
                        .rotationEffect(.degrees(handAngle))
                        .opacity(dotIn ? 1 : 0)

                    // Center dot.
                    Circle()
                        .fill(accent.primary)
                        .frame(width: 12, height: 12)
                        .scaleEffect(dotIn ? 1 : 0)
                }
                .frame(width: 96, height: 96)

                Text("Аванс")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(markColor)
                    .tracking(wordIn ? 2 : 10)
                    .opacity(wordIn ? 1 : 0)
                    .offset(y: wordIn ? 0 : 6)
            }
        }
        .onAppear {
            glow = true
            withAnimation(.easeInOut(duration: 0.65)) { ringTrim = 1 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) { dotIn = true }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.75).delay(0.12)) { handAngle = 40 }
            withAnimation(.easeOut(duration: 0.5).delay(0.42)) { wordIn = true }
        }
    }
}
