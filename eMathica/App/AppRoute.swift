import EMathicaWorkspaceKit
import EMathicaDocumentKit
import Foundation

enum AppRoute: Hashable {
    case home
    case workspace(module: CalculatorModuleType, document: EMathicaDocument)
}
