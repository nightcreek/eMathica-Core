import CoreGraphics
import SwiftUI
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct PlaneVisualPolishTests {
    @Test func keyboardBackplateDoesNotUseStrongMaterialPanel() {
        #expect(WorkspaceInlineInputVisualMetrics.usesStrongKeyboardMaterialBackplate == false)
    }

    @Test func keyboardBackplateIsPrimaryVisibleSupportLayer() {
        #expect(MathKeyboardVisualMetrics.keysBackplateDarkOpacity > 0)
        #expect(MathKeyboardVisualMetrics.keysBackplateLightOpacity > 0)
        #expect(MathKeyboardVisualMetrics.keysBackplateDarkOpacity >= 0.30)
        #expect(MathKeyboardVisualMetrics.keysBackplateDarkOpacity <= 0.36)
        #expect(MathKeyboardVisualMetrics.keysBackplateMaterialDarkOpacity >= 0.42)
        #expect(MathKeyboardVisualMetrics.keysBackplateMaterialDarkOpacity <= 0.50)
        #expect(MathKeyboardVisualMetrics.keysBackplateStrokeDarkOpacity >= 0.22)
        #expect(MathKeyboardVisualMetrics.backplateCornerRadius > 0)
        #expect(MathKeyboardVisualMetrics.backplatePaddingTop >= 8)
        #expect(MathKeyboardVisualMetrics.backplatePaddingBottom >= 8)
        #expect(MathKeyboardVisualMetrics.backplatePaddingHorizontal >= 8)
        #expect(MathKeyboardVisualMetrics.backplateVisualBleedVertical >= 4)
        #expect(MathKeyboardVisualMetrics.backplateVisualBleedHorizontal >= 2)
        #expect(MathKeyboardVisualMetrics.backplateTopHighlightHeight <= 1)
        #expect(MathKeyboardVisualMetrics.backplateBottomShadeHeight <= 4)
        #expect(MathKeyboardVisualMetrics.keysBackplateTopHighlightDarkOpacity <= 0.14)
    }

    @Test func keyboardPanelDoesNotUseVisualClip() {
        #expect(WorkspaceInlineInputVisualMetrics.keyboardPanelUsesVisualClip == false)
    }

    @Test func keyboardKeyVisualOpacityIsNonZero() {
        #expect(MathKeyboardVisualMetrics.keyDarkOpacity > 0)
        #expect(MathKeyboardVisualMetrics.keyLightOpacity > 0)
        #expect(MathKeyboardVisualMetrics.accentKeyDarkOpacity > 0)
        #expect(MathKeyboardVisualMetrics.accentKeyLightOpacity > 0)
        #expect(MathKeyboardVisualMetrics.keyDarkOpacity <= 0.12)
        #expect(MathKeyboardVisualMetrics.keyDarkOpacity <= 0.08)
        #expect(MathKeyboardVisualMetrics.categoryKeyDarkOpacity <= 0.06)
        #expect(MathKeyboardVisualMetrics.accentKeyDarkOpacity <= 0.36)
        #expect(MathKeyboardVisualMetrics.accentKeyDarkOpacity > MathKeyboardVisualMetrics.keyDarkOpacity)
        #expect(MathKeyboardVisualMetrics.categoryActiveDarkOpacity > MathKeyboardVisualMetrics.categoryKeyDarkOpacity)
    }

    @Test func previewIconButtonHitSizeIsAtLeastThirtyTwo() {
        #expect(WorkspaceInlineInputVisualMetrics.iconButtonHitSize >= 32)
    }

    @Test func previewKeyboardSpacingIsWithinTargetRange() {
        #expect(WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing >= 8)
        #expect(WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing <= 18)
        #expect(WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing >= 16)
        #expect(WorkspaceInlineInputVisualMetrics.previewKeyboardSpacing == 16)
    }

    @Test func closedInputUsesOuterEditorBarTapOwner() {
        #expect(WorkspaceInlineInputVisualMetrics.formulaContentHitTestingWhenClosed == false)
    }

    @Test func keyboardPanelUsesMinHeightToken() {
        #expect(WorkspaceInlineInputVisualMetrics.keyboardPanelMinHeight == 216)
    }

    @Test func objectPanelResizeHandleHiddenWhenIdleAndVisibleWhenActive() {
        #expect(WorkspaceObjectPanelHandleVisualMetrics.idleOpacity == 0)
        #expect(WorkspaceObjectPanelHandleVisualMetrics.activeOpacity == 1)
    }

    @Test func inputBarBottomUsesSafeAreaPlusFour() {
        let metrics = WorkspaceLayoutMetrics.make(
            size: CGSize(width: 1366, height: 1024),
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
        #expect(metrics.inputBarBottom == 24)
        let zeroInsetMetrics = WorkspaceLayoutMetrics.make(
            size: CGSize(width: 1366, height: 1024),
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 0, trailing: 0)
        )
        #expect(zeroInsetMetrics.inputBarBottom == 6)
    }

    @Test func inspectorPanelFrameStaysWithinTypicalIPadLandscapeBounds() {
        let size = CGSize(width: 1366, height: 1024)
        let safeInsets = EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        let metrics = WorkspaceLayoutMetrics.make(size: size, safeInsets: safeInsets)

        #expect(metrics.inspectorPanelTop >= safeInsets.top)
        #expect(metrics.inspectorPanelWidth > 0)
        #expect(metrics.inspectorPanelTop + metrics.inspectorPanelMaxHeight <= size.height)
    }

    @Test func previewPanelUsesNonTransparentGlassLayer() {
        #expect(WorkspaceInlineInputVisualMetrics.previewPanelDarkOpacity > 0)
        #expect(WorkspaceInlineInputVisualMetrics.previewPanelLightOpacity > 0)
        #expect(WorkspaceInlineInputVisualMetrics.previewPanelDarkOpacity <= 0.22)
    }

    @Test func toolGroupCapsuleActiveInactiveVisualTokensAreDistinct() {
        #expect(ToolGroupCapsuleVisualMetrics.lightPanelOpacity != ToolGroupCapsuleVisualMetrics.darkPanelOpacity)
        #expect(ToolGroupCapsuleVisualMetrics.lightStrokeOpacity != ToolGroupCapsuleVisualMetrics.darkStrokeOpacity)
    }

    @Test func objectRowSelectedAndUnselectedVisualTokensAreDistinct() {
        #expect(WorkspaceObjectRowVisualMetrics.selectedFillLightOpacity != WorkspaceObjectRowVisualMetrics.unselectedFillLightOpacity)
        #expect(WorkspaceObjectRowVisualMetrics.selectedFillDarkOpacity != WorkspaceObjectRowVisualMetrics.unselectedFillDarkOpacity)
        #expect(WorkspaceObjectRowVisualMetrics.selectedFillDarkOpacity > WorkspaceObjectRowVisualMetrics.unselectedFillDarkOpacity)
    }

    @Test func objectPanelGlassLayerUsesTransparentRange() {
        #expect(AlgebraObjectPanelVisualMetrics.panelDarkOpacity > 0)
        #expect(AlgebraObjectPanelVisualMetrics.panelDarkOpacity <= 0.20)
    }

    @Test func objectPanelHeightMetricsUnaffectedByVisualPolish() {
        let one = AlgebraObjectPanelLayoutMetrics.contentHeight(for: 1)
        let two = AlgebraObjectPanelLayoutMetrics.contentHeight(for: 2)
        #expect(two > one)
    }

    @Test func objectPanelMaxHeightUsesExpandedRatioForWideIPadLikeLayout() {
        let size = CGSize(width: 1366, height: 1024)
        let metrics = WorkspaceLayoutMetrics.make(
            size: size,
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
        #expect(metrics.objectPanelMaxHeight == max(220, size.height * 0.66))
    }

    @Test func objectPanelMaxHeightKeepsConservativeRatioForCompactWidths() {
        let size = CGSize(width: 820, height: 1180)
        let metrics = WorkspaceLayoutMetrics.make(
            size: size,
            safeInsets: EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        )
        #expect(metrics.objectPanelMaxHeight == max(220, size.height * 0.58))
    }
}
