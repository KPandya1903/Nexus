import SwiftUI

// MARK: - Textured Nexus "N" Logo

struct NexusLogo: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            // Base gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#C12A3F"),
                            Color.stevensRed,
                            Color(hex: "#5C0E1C")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle radial glow on top-left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.35), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )

            // Diagonal gradient sheen
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Texture: tiny noise-like dots via mask of small circles
            Canvas { context, canvasSize in
                let count = Int(size * 1.3)
                for i in 0..<count {
                    let seed = Double(i)
                    let x = (sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let y = (sin(seed * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    let px = abs(x) * canvasSize.width
                    let py = abs(y) * canvasSize.height
                    let dotSize = (abs(sin(seed * 3.7)) * 0.8) + 0.4
                    let opacity = abs(sin(seed * 1.9)) * 0.18
                    context.fill(
                        Path(ellipseIn: CGRect(x: px, y: py, width: dotSize, height: dotSize)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
            .mask(Circle())

            // Custom geometric "N"
            NShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 0.5, x: 0, y: 0.5)
                .padding(size * 0.22)

            // Outer hairline ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.5, size * 0.025)
                )
        }
        .frame(width: size, height: size)
        .shadow(color: Color.stevensRed.opacity(0.35), radius: size * 0.15, y: size * 0.06)
    }
}

// MARK: - The "N" glyph as a custom Shape (sharper than the system font)

private struct NShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let strokeW = w * 0.22       // thickness of the vertical bars
        let diagonalW = w * 0.24     // thickness of the diagonal

        // Left vertical bar
        path.addRect(CGRect(x: 0, y: 0, width: strokeW, height: h))

        // Right vertical bar
        path.addRect(CGRect(x: w - strokeW, y: 0, width: strokeW, height: h))

        // Diagonal — top-left to bottom-right
        var diag = Path()
        diag.move(to: CGPoint(x: strokeW, y: 0))
        diag.addLine(to: CGPoint(x: strokeW + diagonalW, y: 0))
        diag.addLine(to: CGPoint(x: w - strokeW, y: h - (h * (diagonalW / (w - 2 * strokeW)))))
        diag.addLine(to: CGPoint(x: w - strokeW, y: h))
        diag.addLine(to: CGPoint(x: w - strokeW - diagonalW, y: h))
        diag.addLine(to: CGPoint(x: strokeW, y: h * (diagonalW / (w - 2 * strokeW))))
        diag.closeSubpath()
        path.addPath(diag)

        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        NexusLogo(size: 30)
        NexusLogo(size: 60)
        NexusLogo(size: 100)
        NexusLogo(size: 160)
    }
    .padding(40)
    .background(Color(.systemBackground))
}
