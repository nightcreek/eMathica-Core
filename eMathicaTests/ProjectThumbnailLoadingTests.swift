import Foundation
import Testing
@testable import eMathica

struct ProjectThumbnailLoadingTests {
    @Test func missingPreviewFileReturnsNil() async throws {
        let url = URL(fileURLWithPath: "/tmp/eMathica-missing-\(UUID().uuidString).png")

        let image = await ProjectThumbnailImageLoader.loadImage(from: url)

        #expect(image == nil)
    }

    @Test func validPreviewFileLoadsAndCachesImage() async throws {
        let url = try makeTemporaryPNGFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let first = await ProjectThumbnailImageLoader.loadImage(from: url)
        let second = await ProjectThumbnailImageLoader.loadImage(from: url)

        let firstImage = try #require(first)
        let secondImage = try #require(second)
        #expect(firstImage === secondImage)
    }

    @Test func corruptPreviewFileReturnsNil() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("eMathica-thumbnail-corrupt-\(UUID().uuidString)")
            .appendingPathExtension("png")
        try Data("not-a-valid-image".utf8).write(to: url, options: [.atomic])
        defer { try? FileManager.default.removeItem(at: url) }

        let image = await ProjectThumbnailImageLoader.loadImage(from: url)

        #expect(image == nil)
    }

    @Test func cacheInvalidatesWhenPreviewFileChanges() async throws {
        let url = try makeTemporaryPNGFile(data: minimalPNGData())
        defer { try? FileManager.default.removeItem(at: url) }

        let firstIdentity = ProjectThumbnailImageLoader.cacheIdentity(for: url)
        let first = await ProjectThumbnailImageLoader.loadImage(from: url)
        _ = try #require(first)

        try minimalPNGData().write(to: url, options: [.atomic])
        let updatedDate = Date().addingTimeInterval(5)
        try FileManager.default.setAttributes([.modificationDate: updatedDate], ofItemAtPath: url.path)

        let secondIdentity = ProjectThumbnailImageLoader.cacheIdentity(for: url)
        let second = await ProjectThumbnailImageLoader.loadImage(from: url)
        _ = try #require(second)

        #expect(firstIdentity != secondIdentity)
    }

    @Test func corruptReplacementDoesNotReuseStaleCachedImage() async throws {
        let url = try makeTemporaryPNGFile(data: minimalPNGData())
        defer { try? FileManager.default.removeItem(at: url) }

        let firstIdentity = ProjectThumbnailImageLoader.cacheIdentity(for: url)
        let first = await ProjectThumbnailImageLoader.loadImage(from: url)
        _ = try #require(first)

        try Data("broken-image-data".utf8).write(to: url, options: [.atomic])
        let updatedDate = Date().addingTimeInterval(5)
        try FileManager.default.setAttributes([.modificationDate: updatedDate], ofItemAtPath: url.path)

        let secondIdentity = ProjectThumbnailImageLoader.cacheIdentity(for: url)
        let second = await ProjectThumbnailImageLoader.loadImage(from: url)

        #expect(firstIdentity != secondIdentity)
        #expect(second == nil)
    }

    @Test func emptyPreviewURLCanBeHandledByCallerFallback() async throws {
        let url: URL? = nil

        let image = await loadPreviewImage(for: url)

        #expect(image == nil)
    }

    private func loadPreviewImage(for url: URL?) async -> PlatformThumbnailImage? {
        guard let url else { return nil }
        return await ProjectThumbnailImageLoader.loadImage(from: url)
    }

    private func makeTemporaryPNGFile(data: Data? = nil) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("eMathica-thumbnail-\(UUID().uuidString)")
            .appendingPathExtension("png")
        try (data ?? minimalPNGData()).write(to: url, options: [.atomic])
        return url
    }

    private func minimalPNGData() -> Data {
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2r8u8AAAAASUVORK5CYII=")!
    }
}
