import SwiftUI
import CoreMotion

/// Lightweight device-motion sampler. Values are plain properties read once
/// per frame by the aurora canvas, so motion never triggers extra SwiftUI
/// invalidations. Safe no-op on devices/simulators without motion.
final class MotionProvider {
    static let shared = MotionProvider()

    private let manager = CMMotionManager()
    private(set) var roll: Double = 0
    private(set) var pitch: Double = 0
    private var started = false

    private init() {}

    func start() {
        guard !started, manager.isDeviceMotionAvailable else { return }
        started = true
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            // Smooth a touch to avoid jitter.
            self.roll = self.roll * 0.85 + m.attitude.roll * 0.15
            self.pitch = self.pitch * 0.85 + m.attitude.pitch * 0.15
        }
    }
}

/// The app-wide background. Switches between a living animated aurora and two
/// calm plain modes (white / black) based on the selected appearance.
struct AppBackground: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var accent: AccentTone

    var body: some View {
        Group {
            if appearance.isAnimated {
                AuroraCanvas(accent: accent, animated: !reduceMotion)
            } else {
                appearance.baseColor
            }
        }
        .ignoresSafeArea()
    }
}

/// GPU-cheap aurora: a handful of soft radial-gradient blobs drawn in a Canvas
/// and animated over time + device tilt. No SwiftUI `.blur`, so no per-frame
/// re-rasterization (this was the source of the previous jank).
private struct AuroraCanvas: View {
    var accent: AccentTone
    var animated: Bool

    private let motion = MotionProvider.shared

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            Canvas { ctx, size in
                draw(ctx: &ctx, size: size,
                     time: animated ? timeline.date.timeIntervalSinceReferenceDate : 0)
            }
        }
        .onAppear { if animated { motion.start() } }
    }

    private func draw(ctx: inout GraphicsContext, size: CGSize, time: Double) {
        // Base fill.
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Appearance.aurora.baseColor))

        let w = size.width, h = size.height
        let mx = CGFloat(motion.roll) * 26
        let my = CGFloat(motion.pitch) * 26

        struct Blob { var bx: CGFloat; var by: CGFloat; var r: CGFloat; var color: Color; var op: Double; var sx: Double; var sy: Double }
        let blobs: [Blob] = [
            Blob(bx: 0.24, by: 0.20, r: 0.95, color: accent.primary,   op: 0.55, sx: 0.13, sy: 0.10),
            Blob(bx: 0.82, by: 0.30, r: 0.85, color: accent.secondary, op: 0.45, sx: 0.10, sy: 0.16),
            Blob(bx: 0.40, by: 0.86, r: 1.00, color: accent.primary,   op: 0.42, sx: 0.16, sy: 0.12),
            Blob(bx: 0.86, by: 0.92, r: 0.78, color: accent.secondary, op: 0.34, sx: 0.12, sy: 0.14)
        ]

        for (i, b) in blobs.enumerated() {
            let phase = time * 0.18 + Double(i) * 1.7
            let dx = CGFloat(sin(phase) * b.sx) * w
            let dy = CGFloat(cos(phase * 0.9) * b.sy) * h
            let cx = b.bx * w + dx + mx * (i % 2 == 0 ? 1 : -1)
            let cy = b.by * h + dy + my * (i % 2 == 0 ? 1 : -1)
            let radius = b.r * max(w, h) * 0.55
            let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            let shading = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [b.color.opacity(b.op), b.color.opacity(0)]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: radius
            )
            ctx.fill(Path(ellipseIn: rect), with: shading)
        }

        // Soft top-down darkening for depth / legibility.
        let vignette = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.28)]),
            startPoint: CGPoint(x: w / 2, y: 0),
            endPoint: CGPoint(x: w / 2, y: h)
        )
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: vignette)
    }
}
