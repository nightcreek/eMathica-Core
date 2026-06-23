import EMathicaDocumentKit
import Foundation
import Observation

@Observable
final class HomeMockProjectStore: ProjectStore {
    var recentProjects: [RecentProject]
    private var documentsByID: [UUID: EMathicaDocument]

    init(
        recentProjects: [RecentProject] = HomeMockProjectStore.defaultProjects(),
        documentsByID: [UUID: EMathicaDocument] = [:]
    ) {
        self.recentProjects = recentProjects
        self.documentsByID = documentsByID
    }

    func delete(ids: Set<UUID>) {
        recentProjects.removeAll(where: { ids.contains($0.id) })
        ids.forEach { documentsByID.removeValue(forKey: $0) }
    }

    func move(ids: Set<UUID>, to moduleID: String) {
        recentProjects = recentProjects.map { project in
            guard ids.contains(project.id) else { return project }
            var updated = project
            updated.moduleID = moduleID
            return updated
        }
    }

    func listProjects() throws -> [RecentProject] {
        recentProjects
    }

    func createProject(metadata: ProjectMetadata, document: EMathicaDocument) throws -> RecentProject {
        let project = RecentProject(
            id: metadata.id,
            title: metadata.title,
            moduleID: metadata.moduleID,
            modifiedDateText: "刚刚",
            thumbnailKindRawValue: "formulaNotes"
        )
        recentProjects.insert(project, at: 0)
        documentsByID[metadata.id] = document
        return project
    }

    func loadProject(id: UUID) throws -> EMathicaDocument {
        if let document = documentsByID[id] {
            return document
        }
        if let project = recentProjects.first(where: { $0.id == id }) {
            let now = Date()
            let metadata = ProjectMetadata(
                id: project.id,
                title: project.title,
                moduleID: project.moduleID,
                createdAt: now,
                updatedAt: now,
                calculatorType: project.moduleID
            )
            let fallback = EMathicaDocument(id: project.id, metadata: metadata, moduleID: project.moduleID, objects: [])
            documentsByID[id] = fallback
            return fallback
        }
        throw ProjectStoreError.projectNotFound(id)
    }

    func saveProject(_ document: EMathicaDocument) throws {
        documentsByID[document.metadata.id] = document
        if let index = recentProjects.firstIndex(where: { $0.id == document.metadata.id }) {
            var updated = recentProjects[index]
            updated.title = document.metadata.title
            updated.moduleID = document.metadata.moduleID
            updated.modifiedDateText = "刚刚"
            recentProjects[index] = updated
        }
    }

    func deleteProject(id: UUID) throws {
        recentProjects.removeAll(where: { $0.id == id })
        documentsByID.removeValue(forKey: id)
    }

    func renameProject(id: UUID, title: String) throws -> RecentProject {
        guard let index = recentProjects.firstIndex(where: { $0.id == id }) else {
            throw ProjectStoreError.projectNotFound(id)
        }
        recentProjects[index].title = title
        recentProjects[index].modifiedDateText = "刚刚"
        if var doc = documentsByID[id] {
            doc.metadata.title = title
            doc.metadata.updatedAt = Date()
            documentsByID[id] = doc
        }
        return recentProjects[index]
    }

    func previewURL(for id: UUID) -> URL? {
        _ = id
        return nil
    }

    static func defaultProjects() -> [RecentProject] {
        [
            RecentProject(title: "二次函数图像研究", moduleID: "plane", modifiedDateText: "今天 09:41", thumbnailKindRawValue: "parabolaGraph"),
            RecentProject(title: "圆的相关与弦定理", moduleID: "plane", modifiedDateText: "昨天 16:27", thumbnailKindRawValue: "circleGeometry"),
            RecentProject(title: "参数曲线拟合", moduleID: "plane", modifiedDateText: "昨天 14:03", thumbnailKindRawValue: "parametricCurve"),
            RecentProject(title: "三维函数曲面", moduleID: "space", modifiedDateText: "5/18 18:20", thumbnailKindRawValue: "surface3D"),
            RecentProject(title: "螺旋楼梯结构", moduleID: "modeling", modifiedDateText: "5/17 10:12", thumbnailKindRawValue: "spiralStairModel"),
            RecentProject(title: "正弦波音色设计", moduleID: "music", modifiedDateText: "5/16 19:22", thumbnailKindRawValue: "synthWaveform"),
            RecentProject(title: "电子乐编曲片段", moduleID: "music", modifiedDateText: "5/16 15:48", thumbnailKindRawValue: "sequencerBlocks"),
            RecentProject(title: "相关性热力图", moduleID: "data", modifiedDateText: "5/16 09:47", thumbnailKindRawValue: "heatmap"),
            RecentProject(title: "销售趋势分析", moduleID: "data", modifiedDateText: "5/15 09:04", thumbnailKindRawValue: "lineChart"),
            RecentProject(title: "笔记与公式整理", moduleID: "notes", modifiedDateText: "5/14 19:17", thumbnailKindRawValue: "formulaNotes")
        ]
    }
}
