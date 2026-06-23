import EMathicaThemeKit
import SwiftUI

struct TouchAestheticBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let layout = HomeBackgroundLayout.resolve(size: proxy.size)
            let theme = HomeBackgroundTheme.forColorScheme(colorScheme)

            ZStack {
                BaseGradientLayer(theme: theme)
                FlowingLightRibbonLayer(layout: layout, theme: theme, reduceMotion: reduceMotion)
                MathDecorationLayer(layout: layout, theme: theme)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
