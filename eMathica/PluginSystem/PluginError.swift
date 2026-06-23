import Foundation

enum PluginError: Error, Hashable {
    case unsupported
    case invalidManifest
    case executionFailed(String)
}
