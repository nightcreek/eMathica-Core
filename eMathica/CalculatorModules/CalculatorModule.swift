import EMathicaWorkspaceKit
import Foundation

struct CalculatorModule: Identifiable, Hashable, Codable {
    let id: CalculatorModuleType
    var title: String
    var subtitle: String
    var iconName: String

    init(id: CalculatorModuleType, title: String, subtitle: String, iconName: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }
}
