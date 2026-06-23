import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import SwiftUI
import CoreGraphics

struct SpaceWorkspaceModuleProvider: WorkspaceModuleProviding {
    let module: CalculatorModuleType = .space
    let toolGroups: [WorkspaceToolGroup] = SpaceToolProvider.defaultToolGroups()
    let commandHandler: ModuleCommandHandler = SpaceCommandHandler()

    func makeCanvasView(context: WorkspaceCanvasContext) -> AnyView {
        AnyView(
            SpaceCanvasView(
                objects: context.objects,
                selectedObjectIDs: context.selectedObjectIDs,
                activeToolID: context.activeToolID,
                cameraState: context.spaceCameraState ?? .default,
                workPlane: context.spaceWorkPlane ?? .xy,
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
        nil
    }

    func buildExpression(
        from source: String,
        fallbackToExplicitY: Bool
    ) -> Result<MathExpression, WorkspaceModuleBuildError> {
        .success(MathExpression(displayText: source))
    }

    // MARK: - Service Protocols

    var geometryDependencyService: (any GeometryDependencyServiceProtocol)? {
        // TODO: Implement SpaceGeometryDependencyService for 3D geometry.
        nil
    }

    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? {
        nil
    }

    var inputCanonicalizer: any InputCanonicalizerProtocol {
        DefaultInputCanonicalizer()
    }
}
