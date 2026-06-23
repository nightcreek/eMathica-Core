import SwiftUI

struct FluidCoreHomeMetrics {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    let pageHorizontalPadding: CGFloat
    let panelHorizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let panelBottomPadding: CGFloat
    let sectionSpacing: CGFloat
    let minHeroPanelGap: CGFloat

    let isHeightConstrained: Bool
    let isVeryHeightConstrained: Bool

    let heroHeight: CGFloat
    let titleFontSize: CGFloat
    let buttonWidth: CGFloat
    let primaryButtonHeight: CGFloat
    let secondaryButtonHeight: CGFloat
    let buttonFontSize: CGFloat
    let heroTitleBottomSpacing: CGFloat
    let buttonSpacing: CGFloat

    let panelHeight: CGFloat
    let panelCornerRadius: CGFloat
    let panelPadding: CGFloat
    let categoryRowHeight: CGFloat

    let cardMinWidth: CGFloat
    let cardMaxWidth: CGFloat
    let cardHeight: CGFloat
    let thumbnailHeight: CGFloat
    let cardSpacing: CGFloat

    let shouldUseScrollView: Bool

    static func resolve(size: CGSize, safeAreaInsets: EdgeInsets) -> FluidCoreHomeMetrics {
        let width = max(1, size.width)
        let height = max(1, size.height)

        let isHeightConstrained = height < 720
        let isVeryHeightConstrained = height < 600

        let pageHorizontalPadding = clamp(width * 0.028, min: 12, max: 36)
        let panelHorizontalPadding: CGFloat
        if width < 700 {
            panelHorizontalPadding = clamp(width * 0.055, min: 18, max: 22)
        } else {
            panelHorizontalPadding = clamp(width * 0.014, min: 10, max: 24)
        }
        let topPadding = clamp(height * 0.018, min: 8, max: 24)
        let bottomPadding = clamp(height * 0.014, min: 6, max: 20)
        let panelBottomPadding = clamp(height * 0.012, min: 6, max: 16)

        let sectionSpacing: CGFloat
        if isVeryHeightConstrained {
            sectionSpacing = 8
        } else if isHeightConstrained {
            sectionSpacing = 12
        } else {
            sectionSpacing = clamp(height * 0.022, min: 14, max: 28)
        }
        let minHeroPanelGap: CGFloat = isVeryHeightConstrained ? 4 : (isHeightConstrained ? 6 : clamp(height * 0.010, min: 8, max: 16))

        let heroHeight: CGFloat
        if isVeryHeightConstrained {
            heroHeight = clamp(height * 0.22, min: 110, max: 150)
        } else if isHeightConstrained {
            heroHeight = clamp(height * 0.25, min: 135, max: 190)
        } else {
            heroHeight = clamp(height * 0.30, min: 180, max: 320)
        }

        let titleFontSize: CGFloat
        if isVeryHeightConstrained {
            titleFontSize = clamp(width * 0.052, min: 38, max: 58)
        } else if isHeightConstrained {
            titleFontSize = clamp(width * 0.060, min: 44, max: 72)
        } else {
            titleFontSize = clamp(width * 0.072, min: 56, max: 96)
        }

        let buttonWidth: CGFloat
        if width < 600 {
            buttonWidth = max(120, width - pageHorizontalPadding * 2)
        } else {
            buttonWidth = clamp(width * 0.36, min: 260, max: 380)
        }
        let heroTitleBottomSpacing: CGFloat = isVeryHeightConstrained ? 12 : (isHeightConstrained ? 18 : 30)
        let buttonSpacing: CGFloat = isVeryHeightConstrained ? 8 : 10
        let primaryButtonHeight: CGFloat = isVeryHeightConstrained ? 40 : (isHeightConstrained ? 44 : 52)
        let secondaryButtonHeight: CGFloat = isVeryHeightConstrained ? 38 : (isHeightConstrained ? 42 : 48)
        let buttonFontSize: CGFloat = isVeryHeightConstrained ? 14 : (isHeightConstrained ? 15 : 17)

        let availableHeight = height - safeAreaInsets.top - safeAreaInsets.bottom - topPadding - bottomPadding
        let rawPanelHeight = availableHeight - heroHeight - sectionSpacing
        let panelHeight = clamp(
            rawPanelHeight,
            min: isVeryHeightConstrained ? 240 : 300,
            max: isHeightConstrained ? 440 : 620
        )
        let shouldUseScrollView = rawPanelHeight < 280 || isVeryHeightConstrained

        let panelCornerRadius = clamp(width * 0.035, min: 24, max: 40)
        let panelPadding = isHeightConstrained ? clamp(width * 0.016, min: 12, max: 16) : clamp(width * 0.018, min: 14, max: 26)
        let categoryRowHeight: CGFloat = isHeightConstrained ? (isVeryHeightConstrained ? 30 : 34) : 40

        let cardSpacing = clamp(width * 0.014, min: 12, max: 20)
        let cardMinWidth = clamp(width * 0.16, min: 150, max: 210)
        let cardMaxWidth = clamp(width * 0.22, min: 190, max: 260)
        let cardHeight: CGFloat
        if isVeryHeightConstrained {
            cardHeight = clamp(height * 0.18, min: 120, max: 140)
        } else if isHeightConstrained {
            cardHeight = clamp(height * 0.19, min: 130, max: 155)
        } else {
            cardHeight = clamp(height * 0.20, min: 145, max: 220)
        }
        let thumbnailHeight: CGFloat
        if isVeryHeightConstrained {
            thumbnailHeight = clamp(cardHeight * 0.45, min: 50, max: 64)
        } else if isHeightConstrained {
            thumbnailHeight = clamp(cardHeight * 0.46, min: 56, max: 72)
        } else {
            thumbnailHeight = clamp(cardHeight * 0.48, min: 64, max: 110)
        }

        return FluidCoreHomeMetrics(
            size: size,
            safeAreaInsets: safeAreaInsets,
            pageHorizontalPadding: pageHorizontalPadding,
            panelHorizontalPadding: panelHorizontalPadding,
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            panelBottomPadding: panelBottomPadding,
            sectionSpacing: sectionSpacing,
            minHeroPanelGap: minHeroPanelGap,
            isHeightConstrained: isHeightConstrained,
            isVeryHeightConstrained: isVeryHeightConstrained,
            heroHeight: heroHeight,
            titleFontSize: titleFontSize,
            buttonWidth: buttonWidth,
            primaryButtonHeight: primaryButtonHeight,
            secondaryButtonHeight: secondaryButtonHeight,
            buttonFontSize: buttonFontSize,
            heroTitleBottomSpacing: heroTitleBottomSpacing,
            buttonSpacing: buttonSpacing,
            panelHeight: panelHeight,
            panelCornerRadius: panelCornerRadius,
            panelPadding: panelPadding,
            categoryRowHeight: categoryRowHeight,
            cardMinWidth: cardMinWidth,
            cardMaxWidth: cardMaxWidth,
            cardHeight: cardHeight,
            thumbnailHeight: thumbnailHeight,
            cardSpacing: cardSpacing,
            shouldUseScrollView: shouldUseScrollView
        )
    }
}

func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
    Swift.min(Swift.max(value, minValue), maxValue)
}
