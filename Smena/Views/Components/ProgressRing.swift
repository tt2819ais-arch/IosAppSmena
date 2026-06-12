import SwiftUI

/// A circular progress ring with a gradient stroke and a center label.
struct ProgressRing<Center: View>: View {
    var progress: Double            // 0...1
    var gradient: LinearGradient
    var lineWidth: CGFloat = 16
    @ViewBuilder var center: () -> Center

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, animated))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)

            center()
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.85).delay(0.15)) {
                animated = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { animated = newValue }
        }
    }
}
