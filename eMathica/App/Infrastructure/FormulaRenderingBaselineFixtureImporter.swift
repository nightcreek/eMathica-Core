import EMathicaDocumentKit
import Foundation

enum FormulaRenderingBaselineFixtureImporter {
    static func fixturePackageURL() -> URL {
        sourceTreeRootURL()
            .appendingPathComponent("DebugFixtures", isDirectory: true)
            .appendingPathComponent(FormulaRenderingBaselineFixture.fixtureDirectoryName, isDirectory: true)
    }

    static func importIntoLocalProjectStore() throws -> UUID {
        let fileManager = FileManager.default
        let sourceURL = fixturePackageURL()
        let layout = EMathicaPackageLayout(rootURL: sourceURL)

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ImportError.fixtureMissing(sourceURL.path)
        }

        let metadataData = try Data(contentsOf: layout.metadataURL)
        let documentData = try Data(contentsOf: layout.documentURL)
        let metadata = try EMathicaPackageCodec.makeDecoder().decode(ProjectMetadata.self, from: metadataData)
        _ = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: documentData)

        let destinationRoot = try localProjectsRootURL()
        let destinationURL = EMathicaPackageLayout.packageURL(for: metadata.id, under: destinationRoot)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return metadata.id
    }

    private static func sourceTreeRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func localProjectsRootURL() throws -> URL {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ImportError.applicationSupportUnavailable
        }
        let projectsRoot = appSupport
            .appendingPathComponent("eMathica", isDirectory: true)
            .appendingPathComponent("Projects", isDirectory: true)
        if !fileManager.fileExists(atPath: projectsRoot.path) {
            try fileManager.createDirectory(at: projectsRoot, withIntermediateDirectories: true)
        }
        return projectsRoot
    }

    enum ImportError: LocalizedError {
        case fixtureMissing(String)
        case applicationSupportUnavailable

        var errorDescription: String? {
            switch self {
            case .fixtureMissing(let path):
                return "未找到基准 fixture：\(path)"
            case .applicationSupportUnavailable:
                return "无法定位 Application Support 目录"
            }
        }
    }
}
