import Foundation

struct PluginResult: Hashable, Codable {
    var pluginID: String
    var message: String

    init(pluginID: String, message: String) {
        self.pluginID = pluginID
        self.message = message
    }
}
