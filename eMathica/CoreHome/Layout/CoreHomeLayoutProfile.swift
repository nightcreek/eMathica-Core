import SwiftUI

enum CoreHomeLayoutProfile {
    case phonePortrait
    case phoneLandscape
    case padPortrait
    case padLandscape
}

struct CoreHomeLayoutMetrics {
    let profile: CoreHomeLayoutProfile
    let heroHeight: CGFloat
    let contentTopPadding: CGFloat
    let horizontalPadding: CGFloat
    let cardColumnCount: Int
    let cardSpacing: CGFloat
    let shouldShowSidebar: Bool
    let shouldShowLargeHeroDecorations: Bool
    let shouldUseCompactActions: Bool

    static func resolve(
        size: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> CoreHomeLayoutMetrics {
        let isPadByWidth = size.width >= 700
        let isPortrait = size.height > size.width
        let isPadBySizeClass = horizontalSizeClass == .regular && verticalSizeClass != .compact
        let isPad = isPadByWidth || isPadBySizeClass

        if isPad {
            if isPortrait {
                return CoreHomeLayoutMetrics(
                    profile: .padPortrait,
                    heroHeight: size.height * 0.34,
                    contentTopPadding: 0,
                    horizontalPadding: 24,
                    cardColumnCount: 4,
                    cardSpacing: 16,
                    shouldShowSidebar: false,
                    shouldShowLargeHeroDecorations: true,
                    shouldUseCompactActions: false
                )
            } else {
                return CoreHomeLayoutMetrics(
                    profile: .padLandscape,
                    heroHeight: size.height * 0.40,
                    contentTopPadding: 0,
                    horizontalPadding: 28,
                    cardColumnCount: 5,
                    cardSpacing: 18,
                    shouldShowSidebar: false,
                    shouldShowLargeHeroDecorations: true,
                    shouldUseCompactActions: false
                )
            }
        }

        if isPortrait {
            return CoreHomeLayoutMetrics(
                profile: .phonePortrait,
                heroHeight: min(300, size.height * 0.33),
                contentTopPadding: 0,
                horizontalPadding: 10,
                cardColumnCount: 2,
                cardSpacing: 12,
                shouldShowSidebar: false,
                shouldShowLargeHeroDecorations: false,
                shouldUseCompactActions: true
            )
        } else {
            return CoreHomeLayoutMetrics(
                profile: .phoneLandscape,
                heroHeight: min(230, size.height * 0.42),
                contentTopPadding: 0,
                horizontalPadding: 10,
                cardColumnCount: 3,
                cardSpacing: 12,
                shouldShowSidebar: false,
                shouldShowLargeHeroDecorations: false,
                shouldUseCompactActions: true
            )
        }
    }
}
