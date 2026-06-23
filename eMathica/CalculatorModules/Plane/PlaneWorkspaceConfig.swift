import EMathicaWorkspaceKit
import Foundation

struct PlaneWorkspaceConfig: Hashable, Codable {
    var showsObjectPanel: Bool = true
    var showsInputBar: Bool = true
    var showsInspector: Bool = true
    var showsMathKeyboard: Bool = false

    static let `default` = PlaneWorkspaceConfig()
}
