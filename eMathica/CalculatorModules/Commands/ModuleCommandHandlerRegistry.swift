import EMathicaWorkspaceKit
import Foundation

enum ModuleCommandHandlerRegistry {
    static func handler(for module: CalculatorModuleType) -> ModuleCommandHandler {
        CalculatorModuleRegistry.moduleProvider(for: module).commandHandler
    }
}

struct NoopCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        switch command {
        case .setActiveTool(let id):
            return ModuleCommandOutput(effects: [.setActiveTool(id: id)])

        case .selectObject(let id):
            return ModuleCommandOutput(effects: [.selectObject(id: id)])

        case .clearSelection:
            return ModuleCommandOutput(effects: [.clearSelection])

        default:
            return ModuleCommandOutput()
        }
    }
}
