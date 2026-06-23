import SwiftUI

struct PadCoreHomeLayout: View {
    @Bindable var state: CoreHomeState
    let metrics: CoreHomeLayoutMetrics
    let fluidMetrics: FluidCoreHomeMetrics
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    private var padTitleFontSize: CGFloat {
        if metrics.profile == .padPortrait {
            return clamp(fluidMetrics.titleFontSize + 10, min: 64, max: 106)
        }
        return fluidMetrics.titleFontSize
    }

    var body: some View {
        ZStack {
            CoreHeroBackgroundView()

            Group {
                if fluidMetrics.shouldUseScrollView {
                    ScrollView(.vertical, showsIndicators: false) {
                        scrollContent
                    }
                } else {
                    fixedContent
                }
            }
        }
    }

    @ViewBuilder
    private var fixedContent: some View {
        VStack(spacing: fluidMetrics.sectionSpacing) {
            CoreHeroHeaderView(
                onPrimaryAction: onPrimaryAction,
                onSecondaryAction: onSecondaryAction,
                titleFontSize: padTitleFontSize,
                buttonWidth: fluidMetrics.buttonWidth,
                primaryButtonHeight: fluidMetrics.primaryButtonHeight,
                secondaryButtonHeight: fluidMetrics.secondaryButtonHeight,
                buttonFontSize: fluidMetrics.buttonFontSize,
                heroTitleBottomSpacing: fluidMetrics.heroTitleBottomSpacing,
                buttonSpacing: fluidMetrics.buttonSpacing
            )
            .frame(height: fluidMetrics.heroHeight, alignment: .center)
            .padding(.horizontal, fluidMetrics.pageHorizontalPadding)

            Spacer(minLength: fluidMetrics.minHeroPanelGap)

            GalleryDrawerView(
                state: state,
                fixedHeight: fluidMetrics.panelHeight,
                showsSidebar: false,
                horizontalPadding: fluidMetrics.panelHorizontalPadding,
                cardColumnCount: nil,
                cardSpacing: fluidMetrics.cardSpacing,
                cardMinWidth: fluidMetrics.cardMinWidth,
                cardMaxWidth: fluidMetrics.cardMaxWidth,
                cardHeight: fluidMetrics.cardHeight,
                thumbnailHeight: fluidMetrics.thumbnailHeight,
                panelCornerRadius: fluidMetrics.panelCornerRadius,
                panelPadding: fluidMetrics.panelPadding,
                categoryRowHeight: fluidMetrics.categoryRowHeight,
                isCompactHeader: fluidMetrics.isHeightConstrained,
                bottomPadding: fluidMetrics.panelBottomPadding
            )
            .frame(height: fluidMetrics.panelHeight)
        }
        .padding(.top, fluidMetrics.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var scrollContent: some View {
        VStack(spacing: fluidMetrics.sectionSpacing) {
            CoreHeroHeaderView(
                onPrimaryAction: onPrimaryAction,
                onSecondaryAction: onSecondaryAction,
                titleFontSize: padTitleFontSize,
                buttonWidth: fluidMetrics.buttonWidth,
                primaryButtonHeight: fluidMetrics.primaryButtonHeight,
                secondaryButtonHeight: fluidMetrics.secondaryButtonHeight,
                buttonFontSize: fluidMetrics.buttonFontSize,
                heroTitleBottomSpacing: fluidMetrics.heroTitleBottomSpacing,
                buttonSpacing: fluidMetrics.buttonSpacing
            )
            .frame(height: fluidMetrics.heroHeight, alignment: .center)
            .padding(.horizontal, fluidMetrics.pageHorizontalPadding)

            GalleryDrawerView(
                state: state,
                fixedHeight: fluidMetrics.panelHeight,
                showsSidebar: false,
                horizontalPadding: fluidMetrics.panelHorizontalPadding,
                cardColumnCount: nil,
                cardSpacing: fluidMetrics.cardSpacing,
                cardMinWidth: fluidMetrics.cardMinWidth,
                cardMaxWidth: fluidMetrics.cardMaxWidth,
                cardHeight: fluidMetrics.cardHeight,
                thumbnailHeight: fluidMetrics.thumbnailHeight,
                panelCornerRadius: fluidMetrics.panelCornerRadius,
                panelPadding: fluidMetrics.panelPadding,
                categoryRowHeight: fluidMetrics.categoryRowHeight,
                isCompactHeader: fluidMetrics.isHeightConstrained,
                bottomPadding: fluidMetrics.panelBottomPadding
            )
            .frame(height: fluidMetrics.panelHeight)
        }
        .padding(.top, fluidMetrics.topPadding)
    }
}
