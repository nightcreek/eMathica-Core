import EMathicaDocumentKit
import Foundation

struct FormulaRenderingBaselineFixtureExportResult: Equatable {
    let fixtureURL: URL
    let reopenedDocument: EMathicaDocument
    let listedProjects: [RecentProject]
}

enum FormulaRenderingBaselineFixtureWriter {
    static func exportFixtureToSourceTree() throws -> FormulaRenderingBaselineFixtureExportResult {
        try exportFixture(to: FormulaRenderingBaselineFixtureImporter.fixturePackageURL())
    }

    static func exportFixture(to destinationURL: URL) throws -> FormulaRenderingBaselineFixtureExportResult {
        let fileManager = FileManager.default
        let built = FormulaRenderingBaselineFixture.build()
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent("emathica-valid-fixture-\(UUID().uuidString)", isDirectory: true)

        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = try LocalProjectStore(
            baseDirectoryURLOverride: temporaryRoot,
            previewRenderer: { _ in nil }
        )
        _ = try store.createProject(metadata: built.document.metadata, document: built.document)

        let reopenedDocument = try store.loadProject(id: built.document.metadata.id)
        let listedProjects = try store.listProjects()
        let generatedPackageURL = EMathicaPackageLayout.packageURL(
            for: built.document.metadata.id,
            under: temporaryRoot.appendingPathComponent("Projects", isDirectory: true)
        )

        let destinationParent = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationParent.path) {
            try fileManager.createDirectory(at: destinationParent, withIntermediateDirectories: true)
        }
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: generatedPackageURL, to: destinationURL)

        return .init(
            fixtureURL: destinationURL,
            reopenedDocument: reopenedDocument,
            listedProjects: listedProjects
        )
    }
}
