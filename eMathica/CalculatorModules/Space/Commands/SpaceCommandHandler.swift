import EMathicaWorkspaceKit
import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

struct SpaceCommandHandler: ModuleCommandHandler {
    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        switch command {
        case .setActiveTool(let id):
            return ModuleCommandOutput(effects: [.setActiveTool(id: id)])

        case .selectObject(let id):
            return ModuleCommandOutput(effects: [.selectObject(id: id)])

        case .clearSelection:
            return ModuleCommandOutput(effects: [.clearSelection])

        case .moduleSpecific(let id, let payload):
            if id == "space.createPoint3D" {
                return handleCreatePoint3D(payload: payload, context: context)
            }
            if id == "space.createSegment3D" {
                return handleCreateSegment3D(payload: payload)
            }
            if id == "space.createLine3D" {
                return handleCreateLine3D(payload: payload)
            }
            if id == "space.createPlane3D" {
                return handleCreatePlane3D(payload: payload)
            }
            return ModuleCommandOutput()

        default:
            return ModuleCommandOutput()
        }
    }

    private func handleCreatePoint3D(payload: String, context: ModuleCommandContext) -> ModuleCommandOutput {
        let decoder = JSONDecoder()
        guard let data = payload.data(using: .utf8),
              let request = try? decoder.decode(SpacePointCreatePayload.self, from: data) else {
            return ModuleCommandOutput(effects: [.showError("3D 点创建参数无效")])
        }

        let name = nextPointName(existing: context.document.objects)
        let object = MathObject(
            name: name,
            type: .point,
            expression: MathExpression(
                displayText: "\(name) = (\(format(request.point.x)), \(format(request.point.y)), \(format(request.point.z)))"
            ),
            geometryDefinition: GeometryDefinition(
                kind: .point3D,
                point3D: request.point
            ),
            style: MathStyle(colorToken: "yellowOrange")
        )
        return ModuleCommandOutput(
            documentCommands: [.addObject(object)],
            effects: [.selectObject(id: object.id)]
        )
    }

    private func handleCreateSegment3D(payload: String) -> ModuleCommandOutput {
        let decoder = JSONDecoder()
        guard let data = payload.data(using: .utf8),
              let request = try? decoder.decode(SpaceSegmentCreatePayload.self, from: data) else {
            return ModuleCommandOutput(effects: [.showError("3D 线段创建参数无效")])
        }

        let name = "S\(shortID())"
        let object = MathObject(
            name: name,
            type: .segment,
            expression: MathExpression(
                displayText: "\(name): (\(format(request.pointA.x)), \(format(request.pointA.y)), \(format(request.pointA.z))) → (\(format(request.pointB.x)), \(format(request.pointB.y)), \(format(request.pointB.z)))"
            ),
            geometryDefinition: GeometryDefinition(
                kind: .segment3D,
                point3D: request.pointA,
                pointB3D: request.pointB
            ),
            style: MathStyle(colorToken: "blue")
        )
        return ModuleCommandOutput(
            documentCommands: [.addObject(object)],
            effects: [.selectObject(id: object.id)]
        )
    }

    private func handleCreateLine3D(payload: String) -> ModuleCommandOutput {
        let decoder = JSONDecoder()
        guard let data = payload.data(using: .utf8),
              let request = try? decoder.decode(SpaceLineCreatePayload.self, from: data) else {
            return ModuleCommandOutput(effects: [.showError("3D 直线创建参数无效")])
        }

        guard request.direction.length > 1e-8 else {
            return ModuleCommandOutput(effects: [.showError("两点过近，无法创建直线")])
        }

        let direction = request.direction
        let name = "L\(shortID())"
        let pointText = "(\(format(request.point.x)), \(format(request.point.y)), \(format(request.point.z))"
        let vectorText = "<\(format(direction.x)), \(format(direction.y)), \(format(direction.z))>"
        let object = MathObject(
            name: name,
            type: .line,
            expression: MathExpression(
                displayText: "\(name): Line3D(\(pointText), \(vectorText))"
            ),
            geometryDefinition: GeometryDefinition(
                kind: .line3D,
                point3D: request.point,
                vector3D: direction
            ),
            style: MathStyle(colorToken: "purple")
        )
        return ModuleCommandOutput(
            documentCommands: [.addObject(object)],
            effects: [.selectObject(id: object.id)]
        )
    }

    private func handleCreatePlane3D(payload: String) -> ModuleCommandOutput {
        let decoder = JSONDecoder()
        guard let data = payload.data(using: .utf8),
              let request = try? decoder.decode(SpacePlaneCreatePayload.self, from: data) else {
            return ModuleCommandOutput(effects: [.showError("3D 平面创建参数无效")])
        }

        let normal = request.normal.normalized()
        guard normal.length > 1e-8 else {
            return ModuleCommandOutput(effects: [.showError("三点共线或过近，无法创建平面")])
        }

        let name = "Π\(shortID())"
        let pointText = "(\(format(request.point.x)), \(format(request.point.y)), \(format(request.point.z)))"
        let normalText = "<\(format(normal.x)), \(format(normal.y)), \(format(normal.z))>"
        let object = MathObject(
            name: name,
            type: .function,
            expression: MathExpression(
                displayText: "\(name): Plane3D(\(pointText), \(normalText))"
            ),
            geometryDefinition: GeometryDefinition(
                kind: .plane3D,
                point3D: request.point,
                vector3D: normal
            ),
            style: MathStyle(colorToken: "cyan")
        )

        return ModuleCommandOutput(
            documentCommands: [.addObject(object)],
            effects: [.selectObject(id: object.id)]
        )
    }

    private func nextPointName(existing: [MathObject]) -> String {
        let used = Set(existing.filter { $0.type == .point }.map(\.name))
        let candidates = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        return candidates.first(where: { !used.contains($0) }) ?? "P"
    }

    private func format(_ value: Double) -> String {
        if !value.isFinite {
            return "0"
        }
        let rounded = (value * 100).rounded() / 100
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(format: "%.2f", rounded)
    }

    private func shortID() -> String {
        String(UUID().uuidString.prefix(4))
    }
}

private struct SpacePointCreatePayload: Codable {
    var point: WorldPoint3D
}

private struct SpaceSegmentCreatePayload: Codable {
    var pointA: WorldPoint3D
    var pointB: WorldPoint3D
}

private struct SpaceLineCreatePayload: Codable {
    var point: WorldPoint3D
    var direction: Vector3D
}

private struct SpacePlaneCreatePayload: Codable {
    var point: WorldPoint3D
    var normal: Vector3D
}
