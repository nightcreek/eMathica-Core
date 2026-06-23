import CoreFoundation
import CoreGraphics
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct AlgebraObjectPanelLayoutMetricsTests {
    @Test func zeroObjectUsesEmptyStateHeightWithoutRowPadding() {
        let height = Double(AlgebraObjectPanelLayoutMetrics.contentHeight(for: 0))
        let expected = AlgebraObjectPanelLayoutMetrics.panelVerticalPadding
            + AlgebraObjectPanelLayoutMetrics.headerHeight
            + AlgebraObjectPanelLayoutMetrics.headerToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.emptyStateHeight
        #expect(height == Double(expected))
    }

    @Test func oneObjectMatchesSingleRowHeight() {
        let height = Double(AlgebraObjectPanelLayoutMetrics.contentHeight(for: 1))
        let expected = AlgebraObjectPanelLayoutMetrics.panelVerticalPadding
            + AlgebraObjectPanelLayoutMetrics.headerHeight
            + AlgebraObjectPanelLayoutMetrics.headerToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.normalRowHeight
        #expect(height == Double(expected))
    }

    @Test func twoObjectsAddsOneSpacingOnly() {
        let one = Double(AlgebraObjectPanelLayoutMetrics.contentHeight(for: 1))
        let two = Double(AlgebraObjectPanelLayoutMetrics.contentHeight(for: 2))
        #expect(
            two - one ==
            Double(AlgebraObjectPanelLayoutMetrics.normalRowHeight + AlgebraObjectPanelLayoutMetrics.rowSpacing)
        )
    }

    @Test func contentHeightForSliderRowsUsesSliderRowHeight() {
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=1"),
            parameterValue: 1,
            style: MathStyle(colorToken: "indigo")
        )
        let height = AlgebraObjectPanelLayoutMetrics.contentHeight(for: [slider])
        let expected = AlgebraObjectPanelLayoutMetrics.panelVerticalPadding
            + AlgebraObjectPanelLayoutMetrics.headerHeight
            + AlgebraObjectPanelLayoutMetrics.headerToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sliderRowHeight
        #expect(height == expected)
    }

    @Test func contentHeightForMixedRowsUsesObjectAwareHeights() {
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=2"),
            parameterValue: 2,
            style: MathStyle(colorToken: "indigo")
        )
        let function = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=sin(x)+a*x"),
            style: MathStyle(colorToken: "indigo")
        )
        let height = AlgebraObjectPanelLayoutMetrics.contentHeight(for: [slider, function])
        let expected = AlgebraObjectPanelLayoutMetrics.panelVerticalPadding
            + AlgebraObjectPanelLayoutMetrics.headerHeight
            + AlgebraObjectPanelLayoutMetrics.headerToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.sliderRowHeight
            + AlgebraObjectPanelLayoutMetrics.sectionSpacing
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderHeight
            + AlgebraObjectPanelLayoutMetrics.sectionHeaderToContentSpacing
            + AlgebraObjectPanelLayoutMetrics.normalRowHeight
        #expect(height == expected)
    }

    @Test func objectAwareHeightExceedsCountOnlyHeightForMixedRows() {
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=2"),
            parameterValue: 2,
            style: MathStyle(colorToken: "indigo")
        )
        let function = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=x^2"),
            style: MathStyle(colorToken: "indigo")
        )
        let objectAware = AlgebraObjectPanelLayoutMetrics.contentHeight(for: [slider, function])
        let countOnly = AlgebraObjectPanelLayoutMetrics.contentHeight(for: 2)
        #expect(objectAware > countOnly)
    }

    @Test func objectPanelSectionsGroupParametersFunctionsAndGeometryInStableOrder() {
        let point = MathObject(
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(0,0)"),
            style: MathStyle(colorToken: "blue")
        )
        let function = MathObject(
            name: "f",
            type: .function,
            expression: MathExpression(displayText: "y=x^2"),
            style: MathStyle(colorToken: "pink")
        )
        let slider = MathObject(
            name: "a",
            type: .parameter,
            expression: MathExpression(displayText: "a=1"),
            parameterValue: 1,
            style: MathStyle(colorToken: "indigo")
        )

        let sections = AlgebraObjectPanelSection.makeSections(from: [point, function, slider])

        #expect(sections.map(\.kind) == [.parameters, .functionsAndCurves, .geometry])
        #expect(sections.map(\.objects.count) == [1, 1, 1])
    }
}
