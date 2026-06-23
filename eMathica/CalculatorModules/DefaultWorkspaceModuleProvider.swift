import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import SwiftUI
import CoreGraphics

struct DefaultWorkspaceModuleProvider: WorkspaceModuleProviding {
    let module: CalculatorModuleType
    let toolGroups: [WorkspaceToolGroup]
    let commandHandler: ModuleCommandHandler = NoopCommandHandler()

    init(module: CalculatorModuleType, toolGroups: [WorkspaceToolGroup]) {
        self.module = module
        self.toolGroups = toolGroups
    }

    func makeCanvasView(context: WorkspaceCanvasContext) -> AnyView {
        switch module {
        case .space:
            return AnyView(SpaceCalculatorPlaceholderView())
        case .modeling:
            return AnyView(ModelingPlaceholderView())
        case .music:
            return AnyView(MusicPlaceholderView())
        case .data:
            return AnyView(DataPlaceholderView())
        case .notes:
            return AnyView(NotesPlaceholderView())
        case .plane:
            return AnyView(EmptyView())
        }
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
        nil
    }

    var semanticIntentAdapter: (any SemanticIntentAdapterProtocol)? {
        nil
    }

    var inputCanonicalizer: any InputCanonicalizerProtocol {
        DefaultInputCanonicalizer()
    }
}
