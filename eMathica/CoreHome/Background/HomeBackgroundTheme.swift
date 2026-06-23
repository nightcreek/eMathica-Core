import EMathicaThemeKit
import SwiftUI

struct HomeBackgroundTheme {
    var baseColors: [Color]
    var ribbonColors: [Color]
    var mathLineOpacity: Double

    static func forColorScheme(_ scheme: ColorScheme) -> HomeBackgroundTheme {
        switch scheme {
        case .dark:
            return HomeBackgroundTheme(
                baseColors: [
                    Color(red: 0.010, green: 0.020, blue: 0.060),
                    Color(red: 0.020, green: 0.070, blue: 0.180),
                    Color(red: 0.070, green: 0.035, blue: 0.180),
                    Color(red: 0.160, green: 0.050, blue: 0.260),
                    Color(red: 0.280, green: 0.030, blue: 0.120)
                ],
                ribbonColors: [
                    Color(red: 0.00, green: 0.65, blue: 1.00),
                    Color(red: 0.45, green: 0.25, blue: 1.00),
                    Color(red: 1.00, green: 0.16, blue: 0.72),
                    Color(red: 0.00, green: 0.95, blue: 0.78)
                ],
                mathLineOpacity: 0.30
            )
        default:
            return HomeBackgroundTheme(
                baseColors: [
                    Color(red: 0.82, green: 0.93, blue: 1.00),
                    Color(red: 0.91, green: 0.97, blue: 1.00),
                    Color(red: 1.00, green: 0.88, blue: 0.97),
                    Color(red: 0.90, green: 0.87, blue: 1.00),
                    Color(red: 0.84, green: 0.95, blue: 1.00)
                ],
                ribbonColors: [
                    Color(red: 0.00, green: 0.64, blue: 1.00),
                    Color(red: 0.42, green: 0.38, blue: 1.00),
                    Color(red: 1.00, green: 0.30, blue: 0.78),
                    Color(red: 0.00, green: 0.88, blue: 0.78),
                    Color.white
                ],
                mathLineOpacity: 0.20
            )
        }
    }
}
