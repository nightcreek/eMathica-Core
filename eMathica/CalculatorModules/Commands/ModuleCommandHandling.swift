import EMathicaWorkspaceKit
import EMathicaDocumentKit
import Foundation

struct ModuleCommandContext: Hashable {
    var document: EMathicaDocument
    var selectedObjectIDs: Set<UUID>

    var inputText: String
}

enum WorkspaceEffect: Hashable {
    case selectObject(id: UUID)
    case selectObjects(Set<UUID>)
    case clearSelection

    case setActiveTool(id: String)

    case openInput(mode: WorkspaceInputMode)
    case closeInput
    case focusInput

    case showKeyboard(Bool)
    case showInspector(Bool)

    case showError(String)
    case showToast(String)
}

struct ModuleCommandOutput: Hashable {
    var documentCommands: [DocumentCommand]
    var effects: [WorkspaceEffect]

    init(documentCommands: [DocumentCommand] = [], effects: [WorkspaceEffect] = []) {
        self.documentCommands = documentCommands
        self.effects = effects
    }
}

protocol ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput
}
