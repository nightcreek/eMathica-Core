import EMathicaDocumentKit
import EMathicaFormulaDisplayCore
import Foundation
import Testing
@testable import EMathicaWorkspaceKit
@testable import eMathica

@MainActor
struct FormulaRenderingBaselineFixtureTests {
    @Test func fixtureDefinitionProducesExpectedInventory() throws {
        let built = FormulaRenderingBaselineFixture.build()

        #expect(built.document.metadata.id == FormulaRenderingBaselineFixture.projectID)
        #expect(built.document.metadata.title == FormulaRenderingBaselineFixture.projectTitle)
        #expect(built.cases.count == 10)
        #expect(built.document.objects.count == built.cases.count)
        #expect(Set(built.cases.map(\.name)).count == built.cases.count)
        #expect(Set(built.document.objects.map(\.id)).count == built.document.objects.count)
        #expect(built.cases.allSatisfy { $0.storageKind == .structured })
    }

    @Test func fixtureWriterRoundTripCreatesOpenablePackage() throws {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("FormulaRenderingBaseline-\(UUID().uuidString).emathica", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: destination) }

        let export = try FormulaRenderingBaselineFixtureWriter.exportFixture(to: destination)
        let layout = EMathicaPackageLayout(rootURL: destination)

        #expect(FileManager.default.fileExists(atPath: destination.path))
        #expect(FileManager.default.fileExists(atPath: layout.metadataURL.path))
        #expect(FileManager.default.fileExists(atPath: layout.documentURL.path))
        #expect(export.reopenedDocument.objects.count == 10)
        #expect(export.listedProjects.contains(where: { $0.id == export.reopenedDocument.metadata.id }))
    }

    @Test func committedFixturePackageMatchesWriterOutputShape() throws {
        let destination = FormulaRenderingBaselineFixtureImporter.fixturePackageURL()
        let layout = EMathicaPackageLayout(rootURL: destination)

        let metadataData = try Data(contentsOf: layout.metadataURL)
        let documentData = try Data(contentsOf: layout.documentURL)
        let metadata = try EMathicaPackageCodec.makeDecoder().decode(ProjectMetadata.self, from: metadataData)
        let document = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: documentData)

        #expect(metadata.id == FormulaRenderingBaselineFixture.projectID)
        #expect(metadata.title == FormulaRenderingBaselineFixture.projectTitle)
        #expect(document.metadata.id == FormulaRenderingBaselineFixture.projectID)
        #expect(document.objects.count == 10)
        #expect(document.objects.map(\.name) == FormulaRenderingBaselineFixture.build().cases.map(\.name))
    }

    @Test func structuredFixtureCasesRestoreDisplayDocumentsAndRender() throws {
        let built = FormulaRenderingBaselineFixture.build()
        let options = FormulaDisplayOptions(renderingBackend: .swiftMath)

        for fixtureCase in built.cases {
            let objectSource = WorkspaceObjectFormulaSource.make(for: fixtureCase.object)
            let document = try #require(objectSource.document, "Missing display document for \(fixtureCase.name)")
            let serialized = FormulaDisplayDocumentSerializer.serialize(document)

            #expect(serialized.contains("\\cursor{}") == false)
            #expect(serialized.contains("\\placeholder{}") == false)

            switch FormulaReadOnlyRenderProbe.measure(document: document, options: options) {
            case .success(let measurement):
                #expect(measurement.width.isFinite)
                #expect(measurement.height.isFinite)
                #expect(measurement.baseline.isFinite)
                #expect(measurement.width > 0)
                #expect(measurement.height > 0)
            case .failure(let reason, let message):
                Issue.record("Structured case \(fixtureCase.name) failed: \(reason.rawValue) \(message)")
            }
        }
    }

    @Test func writerLoadedFixtureCanBeImportedIntoLocalProjectStore() throws {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("FormulaRenderingBaseline-Import-\(UUID().uuidString).emathica", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: destination) }

        _ = try FormulaRenderingBaselineFixtureWriter.exportFixture(to: destination)

        let localStoreRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("emathica-fixture-import-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localStoreRoot) }
        let projectsRoot = localStoreRoot.appendingPathComponent("Projects", isDirectory: true)
        try FileManager.default.createDirectory(at: projectsRoot, withIntermediateDirectories: true)

        let destinationURL = EMathicaPackageLayout.packageURL(
            for: FormulaRenderingBaselineFixture.projectID,
            under: projectsRoot
        )
        try FileManager.default.copyItem(at: destination, to: destinationURL)

        let store = try LocalProjectStore(
            baseDirectoryURLOverride: localStoreRoot,
            previewRenderer: { _ in nil }
        )
        let reopened = try store.loadProject(id: FormulaRenderingBaselineFixture.projectID)

        #expect(reopened.objects.count == 10)
        #expect(reopened.objects.map(\.name) == FormulaRenderingBaselineFixture.build().cases.map(\.name))
        #expect(try store.listProjects().contains(where: { $0.id == FormulaRenderingBaselineFixture.projectID }))
    }
}
