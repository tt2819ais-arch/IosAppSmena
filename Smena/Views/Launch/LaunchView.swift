import SwiftUI

/// ~0.6s launch animation: the logo mark scales up with a spring, a ring
/// sweeps around it, then the title fades in. The parent fades this out.
struct LaunchView: View {
    var accent: AccentTone

    @State private var logoIn = false
    @State private var ringTrim: CGFloat = 0
    @State private var titleIn = false

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A12).ignoresSafeArea()

            // Soft accent glow
            Circle()
                .fill(accent.primary)
                .frame(width: 280, height: 280)
                .opacity(0.5)
                .blur(radius: 90)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: ringTrim)
                        .stroke(accent.gradient,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 104, height: 104)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(accent.gradient)
                        .frame(width: 78, height: 78)
                        .overlay(
                            Image(systemName: "clock.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: accent.primary.opacity(0.6), radius: 18, y: 8)
                        .scaleEffect(logoIn ? 1 : 0.5)
                        .opacity(logoIn ? 1 : 0)
                }

                Text("Смена")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(titleIn ? 1 : 0)
                    .offset(y: titleIn ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { logoIn = true }
            withAnimation(.easeInOut(duration: 0.55)) { ringTrim = 1 }
            withAnimation(.easeOut(duration: 0.4).delay(0.18)) { titleIn = true }
        }
    }
}
