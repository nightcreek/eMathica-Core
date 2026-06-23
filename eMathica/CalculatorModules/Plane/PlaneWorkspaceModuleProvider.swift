import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import SwiftUI
import CoreGraphics

struct PlaneWorkspaceModuleProvider: WorkspaceModuleProviding {
    let module: CalculatorModuleType = .plane
    let toolGroups: [WorkspaceToolGroup] = PlaneToolProvider.defaultToolGroups()
    let commandHandler: ModuleCommandHandler = PlaneCommandHandler()
    let startsWithObjectPanelCollapsed: Bool = true
    let autoRevealsInspectorOnSelection: Bool = true
    let autoHidesInspectorOnSelectionClear: Bool = true

    func makeCanvasView(context: WorkspaceCanvasContext) -> AnyView {
        AnyView(
            PlaneCanvasView(
                canvasState: context.canvasState,
                objects: context.objects,
                selectedObjectID: context.selectedObjectID,
                activeToolID: context.activeToolID,
                draftMathObject: context.draftMathObject,
                dispatch: context.dispatch
            )
        )
    }

    func makeDraftMathObject(
        formulaInputState: FormulaInputState,
        document: EMathicaDocument,
        previous: DraftMathObject?,
        canvasPixelSize: CGSize?,
        canvasInteracting: Bool
    ) -> DraftMathObject? {
        #if DEBUG
        print("[PlanePreview][Provider] makeDraft source=\"\(formulaInputState.source)\" compute=\"\(formulaInputState.computeExpression)\" prev=\(previous == nil ? "nil" : "non-nil")")
        #endif
        return PlaneDraftPreviewService.makeDraft(
            formulaInputState: formulaInputState,
            document: document,
            previous: previous,
            canvasPixelSize: canvasPixelSize,
            isCanvasInteracting: canvasInteracting
        )
    }

    func buildExpression(
        from source: String,
        fallbackToExplicitY: Bool
    ) -> Result<MathExpression, WorkspaceModuleBuildError> {
        PlaneExpressionService.buildExpression(from: source, fallbackToExplicitY: fallbackToExplicitY)
    }

    // MARK: - Service Protocols

    var geometryDependencyService: (any GeometryDependencyServiceProtocol)? {
        PlaneGeometryDependencyService()
    }

    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? {
        PlaneSemanticIntentAdapter()
    }

    var inputCanonicalizer: any InputCanonicalizerProtocol {
        PlaneInputCanonicalizer()
    }

    var objectNamingService: (any WorkspaceObjectNamingServiceProtocol)? {
        PlaneObjectNamingService()
    }

    var geometryPresentationResolver: (any GeometryPresentationResolverProtocol)? {
        PlaneGeometryPresentationResolver()
    }

    func canEditExpression(for object: MathObject) -> Bool {
        switch object.type {
        case .function, .point, .circle, .parameter:
            return true
        case .segment, .line, .ray, .parameterGroup, .arc:
            return false
        }
    }
}
