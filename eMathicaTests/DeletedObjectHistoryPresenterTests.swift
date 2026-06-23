import Foundation
import Testing
import EMathicaDocumentKit
@testable import EMathicaMathCore
import EMathicaMathInputCore
@testable import EMathicaWorkspaceKit
@testable import eMathica

struct DeletedObjectHistoryPresenterTests {
    @Test func emptyStateCopyIsDefined() {
        #expect(DeletedObjectHistoryPresenter.emptyTitle == "没有可恢复的对象")
        #expect(DeletedObjectHistoryPresenter.emptyMessage.contains("最多保留最近 200 个"))
    }

    @Test func contextLabelsAreMapped() {
        #expect(DeletedObjectHistoryPresenter.contextLabel(for: .userDelete) == "手动删除")
        #expect(DeletedObjectHistoryPresenter.contextLabel(for: .deleteAffected) == "删除相关对象")
        #expect(DeletedObjectHistoryPresenter.contextLabel(for: .unknown) == "未知来源")
        #expect(DeletedObjectHistoryPresenter.contextLabel(for: nil) == "未知来源")
    }

    @Test func rowModelContainsNameTypeContextAndSummary() {
        let point = MathObject(
            id: UUID(),
            name: "A",
            type: .point,
            expression: MathExpression(displayText: "A=(1,2)"),
            position: WorldPoint(x: 1.234, y: 2.345),
            geometryDefinition: GeometryDefinition(kind: .point, anchors: []),
            style: MathStyle(colorToken: "yellowOrange")
        )
        let record = DeletedObjectRecord(
            id: UUID(),
            deletedAt: Date(timeIntervalSince1970: 1_700_000_000),
            object: point,
            context: .userDelete
        )
        let rows = DeletedObjectHistoryPresenter.rowModels(from: [record])
        let row = try! #require(rows.first)

        #expect(row.name == "A")
        #expect(row.typeLabel == "点")
        #expect(row.contextText == "手动删除")
        #expect(row.summaryText.contains("坐标"))
    }

    @Test func summaryFallsBackToTypeWhenExpressionEmpty() {
        let obj = MathObject(
            id: UUID(),
            name: "L",
            type: .line,
            expression: MathExpression(displayText: ""),
            geometryDefinition: GeometryDefinition(kind: .line, anchors: []),
            style: MathStyle(colorToken: "green")
        )
        let text = DeletedObjectHistoryPresenter.summary(for: obj)
        #expect(text == "直线")
    }
}
