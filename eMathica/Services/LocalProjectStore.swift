import EMathicaDocumentKit
import Foundation

struct LocalProjectStore: ProjectStore {
    private let fileManager: FileManager
    private let baseDirectoryURL: URL
    private let projectsDirectoryURL: URL
    private let previewRenderer: (EMathicaDocument) -> Data?

    init(
        fileManager: FileManager = .default,
        baseDirectoryURLOverride: URL? = nil,
        previewRenderer: @escaping (EMathicaDocument) -> Data? = { ProjectPreviewRenderer.renderPNGData(for: $0) }
    ) throws {
        self.fileManager = fileManager
        self.previewRenderer = previewRenderer
        if let baseDirectoryURLOverride {
            self.baseDirectoryURL = baseDirectoryURLOverride
        } else if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            self.baseDirectoryURL = appSupport.appendingPathComponent("eMathica", isDirectory: true)
        } else {
            throw ProjectStoreError.ioFailed("无法获取 Application Support 目录")
        }
        self.projectsDirectoryURL = baseDirectoryURL.appendingPathComponent("Projects", isDirectory: true)
        try ensureDirectories()
    }

    func listProjects() throws -> [RecentProject] {
        try ensureDirectories()
        let urls = try fileManager.contentsOfDirectory(
            at: projectsDirectoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var pairs: [(project: RecentProject, updatedAt: Date)] = []
        for url in urls where url.pathExtension == EMathicaPackageLayout.packageExtension {
            let layout = EMathicaPackageLayout(rootURL: url)
            guard let metadata = try? loadMetadata(from: layout.metadataURL) else {
                continue
            }
            let project = makeRecentProject(from: metadata)
            pairs.append((project, metadata.updatedAt))
        }

        return pairs
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(\.project)
    }

    func createProject(metadata: ProjectMetadata, document: EMathicaDocument) throws -> RecentProject {
        try ensureDirectories()
        var storedDocument = document
        var storedMetadata = metadata
        let now = Date()
        storedMetadata.createdAt = now
        storedMetadata.updatedAt = now
        storedDocument.metadata = storedMetadata

        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: storedMetadata.id, under: projectsDirectoryURL))
        if fileManager.fileExists(atPath: layout.rootURL.path) {
            throw ProjectStoreError.ioFailed("项目已存在：\(storedMetadata.id.uuidString)")
        }

        do {
            try fileManager.createDirectory(at: layout.rootURL, withIntermediateDirectories: true)
            try saveMetadata(storedMetadata, to: layout.metadataURL)
            try saveDocument(storedDocument, to: layout.documentURL)
            updatePreviewIfPossible(for: storedDocument, at: layout.previewURL)
        } catch {
            throw normalizeIOError(error)
        }

        return makeRecentProject(from: storedMetadata)
    }

    func loadProject(id: UUID) throws -> EMathicaDocument {
        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: id, under: projectsDirectoryURL))
        guard fileManager.fileExists(atPath: layout.rootURL.path) else {
            throw ProjectStoreError.projectNotFound(id)
        }
        guard fileManager.fileExists(atPath: layout.documentURL.path) else {
            throw ProjectStoreError.invalidPackage(layout.rootURL)
        }
        do {
            let data = try Data(contentsOf: layout.documentURL)
            let document = try EMathicaPackageCodec.makeDecoder().decode(EMathicaDocument.self, from: data)
            return document
        } catch {
            throw ProjectStoreError.decodingFailed("读取 document.json 失败：\(error.localizedDescription)")
        }
    }

    func saveProject(_ document: EMathicaDocument) throws {
        try ensureDirectories()
        let projectID = document.metadata.id
        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: projectID, under: projectsDirectoryURL))
        guard fileManager.fileExists(atPath: layout.rootURL.path) else {
            throw ProjectStoreError.projectNotFound(projectID)
        }

        var storedDocument = document
        var metadata = storedDocument.metadata
        metadata.updatedAt = Date()
        storedDocument.metadata = metadata

        do {
            try saveMetadata(metadata, to: layout.metadataURL)
            try saveDocument(storedDocument, to: layout.documentURL)
            updatePreviewIfPossible(for: storedDocument, at: layout.previewURL)
        } catch {
            throw normalizeIOError(error)
        }
    }

    func deleteProject(id: UUID) throws {
        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: id, under: projectsDirectoryURL))
        guard fileManager.fileExists(atPath: layout.rootURL.path) else {
            throw ProjectStoreError.projectNotFound(id)
        }
        do {
            try fileManager.removeItem(at: layout.rootURL)
        } catch {
            throw normalizeIOError(error)
        }
    }

    func renameProject(id: UUID, title: String) throws -> RecentProject {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProjectStoreError.ioFailed("项目名称不能为空")
        }

        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: id, under: projectsDirectoryURL))
        guard fileManager.fileExists(atPath: layout.rootURL.path) else {
            throw ProjectStoreError.projectNotFound(id)
        }

        var metadata = try loadMetadata(from: layout.metadataURL)
        var document = try loadProject(id: id)
        metadata.title = trimmed
        metadata.updatedAt = Date()
        document.metadata = metadata

        do {
            try saveMetadata(metadata, to: layout.metadataURL)
            try saveDocument(document, to: layout.documentURL)
        } catch {
            throw normalizeIOError(error)
        }

        return makeRecentProject(from: metadata)
    }

    func previewURL(for id: UUID) -> URL? {
        let layout = EMathicaPackageLayout(rootURL: EMathicaPackageLayout.packageURL(for: id, under: projectsDirectoryURL))
        let url = layout.previewURL
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func ensureDirectories() throws {
        do {
            if !fileManager.fileExists(atPath: baseDirectoryURL.path) {
                try fileManager.createDirectory(at: baseDirectoryURL, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: projectsDirectoryURL.path) {
                try fileManager.createDirectory(at: projectsDirectoryURL, withIntermediateDirectories: true)
            }
        } catch {
            throw normalizeIOError(error)
        }
    }

    private func loadMetadata(from url: URL) throws -> ProjectMetadata {
        guard fileManager.fileExists(atPath: url.path) else {
            throw ProjectStoreError.invalidPackage(url.deletingLastPathComponent())
        }
        do {
            let data = try Data(contentsOf: url)
            return try EMathicaPackageCodec.makeDecoder().decode(ProjectMetadata.self, from: data)
        } catch {
            throw ProjectStoreError.decodingFailed("读取 metadata.json 失败：\(error.localizedDescription)")
        }
    }

    private func saveMetadata(_ metadata: ProjectMetadata, to url: URL) throws {
        do {
            let data = try EMathicaPackageCodec.makeEncoder().encode(metadata)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw ProjectStoreError.encodingFailed("写入 metadata.json 失败：\(error.localizedDescription)")
        }
    }

    private func saveDocument(_ document: EMathicaDocument, to url: URL) throws {
        do {
            let data = try EMathicaPackageCodec.makeEncoder().encode(document)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw ProjectStoreError.encodingFailed("写入 document.json 失败：\(error.localizedDescription)")
        }
    }

    private func makeRecentProject(from metadata: ProjectMetadata) -> RecentProject {
        RecentProject(
            id: metadata.id,
            title: metadata.title,
            moduleID: metadata.moduleID,
            modifiedDateText: DateTextFormatter.modifiedDateText(from: metadata.updatedAt),
            thumbnailKindRawValue: "formulaNotes",
            fileExtension: ".emathica",
            isSelected: false
        )
    }

    private func normalizeIOError(_ error: Error) -> ProjectStoreError {
        if let storeError = error as? ProjectStoreError {
            return storeError
        }
        return .ioFailed(error.localizedDescription)
    }

    private func updatePreviewIfPossible(for document: EMathicaDocument, at url: URL) {
        guard let pngData = previewRenderer(document) else {
            removePreviewIfExists(at: url)
            return
        }
        do {
            try pngData.write(to: url, options: [.atomic])
        } catch {
            removePreviewIfExists(at: url)
        }
    }

    private func removePreviewIfExists(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }
}

private enum DateTextFormatter {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    static func modifiedDateText(from date: Date) -> String {
        formatter.string(from: date)
    }
}
