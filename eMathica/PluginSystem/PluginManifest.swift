import Foundation

struct PluginManifest: Hashable, Codable {
    var id: String
    var displayName: String
    var version: String

    init(id: String, displayName: String, version: String) {
        self.id = id
        self.displayName = displayName
        self.version = version
    }
}
