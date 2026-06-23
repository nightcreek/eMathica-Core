import Foundation
import Testing
import EMathicaDocumentKit
@testable import eMathica

struct LocalProjectStorePreviewFallbackTests {
    @Test func previewGenerationFailureRemovesExistingPreviewFile() throws {
        let baseDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("eMathica-preview-fallback-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectoryURL) }

        let rendererBox = PreviewRendererBox(data: minimalPNGData())
        let store = try LocalProjectStore(
            baseDirectoryURLOverride: baseDirectoryURL,
            previewRenderer: { rendererBox.render(for: $0) }
        )

        let now = Date()
        let metadata = ProjectMetadata(
            title: "Preview Failure Fallback",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )

        _ = try store.createProject(metadata: metadata, document: document)
        let previewURL = try #require(store.previewURL(for: metadata.id))
        #expect(FileManager.default.fileExists(atPath: previewURL.path))

        rendererBox.data = nil
        try store.saveProject(document)

        #expect(store.previewURL(for: metadata.id) == nil)
        #expect(FileManager.default.fileExists(atPath: previewURL.path) == false)

        let reopened = try store.loadProject(id: metadata.id)
        #expect(reopened.metadata.id == metadata.id)
        #expect(reopened.metadata.title == metadata.title)
    }

    @Test func createProjectWithoutPreviewGenerationLeavesNoPreviewFile() throws {
        let baseDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("eMathica-preview-missing-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectoryURL) }

        let store = try LocalProjectStore(
            baseDirectoryURLOverride: baseDirectoryURL,
            previewRenderer: { _ in nil }
        )

        let now = Date()
        let metadata = ProjectMetadata(
            title: "Preview Missing",
            moduleID: "plane",
            createdAt: now,
            updatedAt: now,
            calculatorType: "plane"
        )
        let document = EMathicaDocument(
            metadata: metadata,
            moduleID: "plane",
            objects: []
        )

        _ = try store.createProject(metadata: metadata, document: document)

        #expect(store.previewURL(for: metadata.id) == nil)
        let reopened = try store.loadProject(id: metadata.id)
        #expect(reopened.metadata.id == metadata.id)
    }
}

private final class PreviewRendererBox {
    var data: Data?

    init(data: Data?) {
        self.data = data
    }

    func render(for _: EMathicaDocument) -> Data? {
        data
    }
}

private func minimalPNGData() -> Data {
    Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2r8u8AAAAASUVORK5CYII=")!
}
