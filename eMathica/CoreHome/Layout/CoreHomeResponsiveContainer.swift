import SwiftUI

struct CoreHomeResponsiveContainer: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Bindable var state: CoreHomeState
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let fluidMetrics = FluidCoreHomeMetrics.resolve(
                size: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets
            )
            let metrics = CoreHomeLayoutMetrics.resolve(
                size: proxy.size,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
            switch metrics.profile {
            case .padPortrait, .padLandscape:
                PadCoreHomeLayout(
                    state: state,
                    metrics: metrics,
                    fluidMetrics: fluidMetrics,
                    onPrimaryAction: onPrimaryAction,
                    onSecondaryAction: onSecondaryAction
                )
            case .phonePortrait, .phoneLandscape:
                PhoneCoreHomeLayout(
                    state: state,
                    metrics: metrics,
                    onPrimaryAction: onPrimaryAction,
                    onSecondaryAction: onSecondaryAction
                )
            }
        }
    }
}
