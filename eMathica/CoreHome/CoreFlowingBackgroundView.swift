import SwiftUI

struct CoreFlowingBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                baseGradient

                if colorScheme == .light {
                    flowingGlowLayer(size: size)
                    lightRibbonLayer(size: size)
                } else {
                    darkGlowLayer(size: size)
                }

                HStack(spacing: 0) {
                    FunctionLineArtView()
                        .opacity(colorScheme == .dark ? 0.24 : 0.12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    GeometryLineArtView()
                        .opacity(colorScheme == .dark ? 0.22 : 0.11)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .blendMode(colorScheme == .dark ? .plusLighter : .normal)
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 140)
            }
            .ignoresSafeArea()
        }
    }

    private var baseGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.22),
                    Color(red: 0.12, green: 0.12, blue: 0.32),
                    Color(red: 0.18, green: 0.10, blue: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 1.0),
                    Color(red: 0.94, green: 0.97, blue: 1.0),
                    Color(red: 0.96, green: 0.94, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func flowingGlowLayer(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.14))
                .blur(radius: 70)
                .frame(width: min(size.width, 760), height: min(size.width, 760))
                .offset(x: -size.width * 0.22, y: -size.height * 0.18)

            Circle()
                .fill(Color.blue.opacity(0.13))
                .blur(radius: 80)
                .frame(width: min(size.width, 820), height: min(size.width, 820))
                .offset(x: size.width * 0.18, y: -size.height * 0.20)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .blur(radius: 90)
                .frame(width: min(size.width, 920), height: min(size.width, 920))
                .offset(x: size.width * 0.05, y: -size.height * 0.28)

            RoundedRectangle(cornerRadius: 140, style: .continuous)
                .fill(Color.pink.opacity(0.07))
                .blur(radius: 84)
                .frame(width: size.width * 0.96, height: size.height * 0.62)
                .offset(y: -size.height * 0.10)
        }
    }

    private func darkGlowLayer(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.38))
                .blur(radius: 60)
                .frame(width: min(size.width, 520), height: min(size.width, 520))
                .offset(x: -size.width * 0.18, y: -size.height * 0.12)

            Circle()
                .fill(Color.purple.opacity(0.30))
                .blur(radius: 70)
                .frame(width: min(size.width, 520), height: min(size.width, 520))
                .offset(x: size.width * 0.22, y: -size.height * 0.10)

            Circle()
                .fill(Color.pink.opacity(0.10))
                .blur(radius: 90)
                .frame(width: min(size.width, 620), height: min(size.width, 620))
                .offset(x: size.width * 0.05, y: -size.height * 0.18)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.indigo.opacity(0.18))
                .blur(radius: 84)
                .frame(width: size.width * 0.94, height: size.height * 0.62)
                .offset(y: -size.height * 0.10)
        }
    }

    private func lightRibbonLayer(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)

            context.addFilter(.blur(radius: 18))

            var p1 = Path()
            p1.move(to: CGPoint(x: rect.minX - 40, y: rect.midY - rect.height * 0.22))
            p1.addCurve(
                to: CGPoint(x: rect.maxX + 40, y: rect.midY - rect.height * 0.10),
                control1: CGPoint(x: rect.midX * 0.35, y: rect.minY + rect.height * 0.12),
                control2: CGPoint(x: rect.midX * 1.10, y: rect.midY - rect.height * 0.45)
            )

            var p2 = Path()
            p2.move(to: CGPoint(x: rect.minX - 40, y: rect.midY + rect.height * 0.08))
            p2.addCurve(
                to: CGPoint(x: rect.maxX + 40, y: rect.midY + rect.height * 0.22),
                control1: CGPoint(x: rect.midX * 0.40, y: rect.midY - rect.height * 0.05),
                control2: CGPoint(x: rect.midX * 1.06, y: rect.midY + rect.height * 0.35)
            )

            let s1 = StrokeStyle(lineWidth: 34, lineCap: .round)
            let s2 = StrokeStyle(lineWidth: 26, lineCap: .round)

            context.stroke(p1, with: .color(Color.white.opacity(0.30)), style: s1)
            context.stroke(p1, with: .color(Color.cyan.opacity(0.18)), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            context.stroke(p2, with: .color(Color.white.opacity(0.22)), style: s2)
            context.stroke(p2, with: .color(Color.purple.opacity(0.14)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
        }
        .opacity(0.55)
    }
}
