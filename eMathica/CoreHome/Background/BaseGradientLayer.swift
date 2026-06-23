import EMathicaThemeKit
import SwiftUI

struct BaseGradientLayer: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: HomeBackgroundTheme

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(
                    colors: [theme.baseColors[0], theme.baseColors[1]],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [theme.baseColors[0].opacity(colorScheme == .dark ? 0.82 : 0.38), .clear],
                    center: UnitPoint(x: 0.10, y: 0.08),
                    startRadius: 0,
                    endRadius: size.width * 0.58
                )

                RadialGradient(
                    colors: [theme.baseColors[2].opacity(colorScheme == .dark ? 0.80 : 0.34), .clear],
                    center: UnitPoint(x: 0.87, y: 0.12),
                    startRadius: 0,
                    endRadius: size.width * 0.52
                )

                RadialGradient(
                    colors: [theme.baseColors[3].opacity(colorScheme == .dark ? 0.74 : 0.30), .clear],
                    center: UnitPoint(x: 0.86, y: 0.86),
                    startRadius: 0,
                    endRadius: size.width * 0.64
                )

                RadialGradient(
                    colors: [theme.baseColors[4].opacity(colorScheme == .dark ? 0.52 : 0.24), .clear],
                    center: UnitPoint(x: 0.14, y: 0.84),
                    startRadius: 0,
                    endRadius: size.width * 0.66
                )

                RadialGradient(
                    colors: [Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12), .clear],
                    center: UnitPoint(x: 0.54, y: 0.42),
                    startRadius: 0,
                    endRadius: size.width * 0.46
                )

                RadialGradient(
                    colors: [Color(red: 0.72, green: 0.92, blue: 1.00).opacity(colorScheme == .dark ? 0.00 : 0.22), .clear],
                    center: UnitPoint(x: 0.28, y: 0.90),
                    startRadius: 0,
                    endRadius: size.width * 0.48
                )
            }
        }
    }
}
