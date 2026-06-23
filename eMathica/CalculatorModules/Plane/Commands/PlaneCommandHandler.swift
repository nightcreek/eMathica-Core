import EMathicaWorkspaceKit
import EMathicaThemeKit
import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

struct PlaneCommandHandler: ModuleCommandHandler {
    private let namingService = PlaneObjectNamingService()

    func handle(_ command: WorkspaceCommand, context: ModuleCommandContext) -> ModuleCommandOutput {
        switch command {
        case .setActiveTool(let id):
            return ModuleCommandOutput(effects: [.setActiveTool(id: id)])

        case .selectObject(let id):
            return ModuleCommandOutput(effects: [.selectObject(id: id)])

        case .clearSelection:
            return ModuleCommandOutput(effects: [.clearSelection])

        case .deleteObject(let id):
            return ModuleCommandOutput(
                documentCommands: [.deleteObject(id: id)],
                effects: [.clearSelection, .showToast("已删除")]
            )

        case .deleteObjects(let ids):
            let deduped = Array(Set(ids))
            guard !deduped.isEmpty else { return ModuleCommandOutput() }
            return ModuleCommandOutput(
                documentCommands: [.deleteObjects(deduped)],
                effects: [.clearSelection, .showToast("已删除\(deduped.count)项")]
            )

        case .deleteSelectedObjects:
            let ids = Array(context.selectedObjectIDs)
            guard !ids.isEmpty else { return ModuleCommandOutput() }
            return ModuleCommandOutput(
                documentCommands: [.deleteObjects(ids)],
                effects: [.clearSelection, .showToast("已删除\(ids.count)项")]
            )

        case .duplicateSelectedObjects:
            let selected = context.document.objects.filter { context.selectedObjectIDs.contains($0.id) }
            guard !selected.isEmpty else { return ModuleCommandOutput() }

            var commands: [DocumentCommand] = []
            var newIDs: Set<UUID> = []
            for object in selected {
                let copy = MathObject(
                    name: object.name + " 副本",
                    type: object.type,
                    expression: object.expression,
                    position: object.position,
                    style: object.style,
                    isVisible: object.isVisible
                )
                commands.append(.addObject(copy))
                newIDs.insert(copy.id)
            }

            return ModuleCommandOutput(
                documentCommands: commands,
                effects: [.selectObjects(newIDs), .showToast("已复制\(selected.count)项")]
            )

        case .renameObject(let id, let newName):
            return ModuleCommandOutput(
                documentCommands: [.renameObject(id: id, name: newName)],
                effects: [.showToast("已重命名")]
            )

        case .toggleObjectVisibility(let id):
            guard let object = context.document.objects.first(where: { $0.id == id }) else {
                return ModuleCommandOutput(effects: [.showError("找不到要切换显示的对象")])
            }
            return ModuleCommandOutput(documentCommands: [.setObjectVisibility(id: id, isVisible: !object.isVisible)])

        case .updateObjectStyle(let id, let colorToken, let opacity, let fillOpacity, let lineWidth, let pointSize, let lineStyle):
            guard context.document.objects.contains(where: { $0.id == id }) else {
                return ModuleCommandOutput(effects: [.showError("找不到要更新样式的对象")])
            }
            return ModuleCommandOutput(documentCommands: [.updateObject(
                id: id,
                patch: DocumentObjectPatch(
                    styleColorToken: colorToken,
                    styleOpacity: opacity,
                    styleFillOpacity: fillOpacity,
                    styleLineWidth: lineWidth,
                    stylePointSize: pointSize,
                    styleLineStyle: lineStyle
                )
            )])

        case .updateObjectPosition(let id, let position):
            guard let object = context.document.objects.first(where: { $0.id == id }) else {
                return ModuleCommandOutput(effects: [.showError("找不到要移动的对象")])
            }
            guard object.type == .point else {
                return ModuleCommandOutput()
            }
            guard object.geometryDependency == nil else {
                return ModuleCommandOutput()
            }

            let display = "\(object.name) = (\(format(position.x)), \(format(position.y)))"
            let patch = DocumentObjectPatch(
                expressionDisplayText: display,
                position: position
            )
            return ModuleCommandOutput(documentCommands: [.updateObject(id: id, patch: patch)])

        case .convertObjectToStatic(let id):
            guard let object = context.document.objects.first(where: { $0.id == id }) else {
                return ModuleCommandOutput(effects: [.showError("找不到对象")])
            }
            guard object.geometryDependency != nil else {
                return ModuleCommandOutput()
            }
            return ModuleCommandOutput(
                documentCommands: [
                    .updateObject(
                        id: id,
                        patch: DocumentObjectPatch(
                            clearGeometryDependency: true,
                            clearGeometryDefinitionStatus: true
                        )
                    )
                ]
            )

        case .restoreDeletedObject:
            return ModuleCommandOutput()

        case .createPoint(let worldPoint):
            let name = namingService.nextPointName(existingObjects: context.document.objects)
            let display = "\(name) = (\(format(worldPoint.x)), \(format(worldPoint.y)))"
            let object = MathObject(
                name: name,
                type: .point,
                expression: MathExpression(displayText: display),
                position: worldPoint,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "yellowOrange")
            )
            return ModuleCommandOutput(
                documentCommands: [.addObject(object)],
                effects: [.selectObject(id: object.id)]
            )

        case .createFunction(let expression):
            let built = PlaneExpressionService.buildExpression(from: expression, fallbackToExplicitY: true)
            let builtExpression: MathExpression
            switch built {
            case .success(let value):
                builtExpression = value
            case .failure(let error):
                return ModuleCommandOutput(effects: [.showError(error.message)])
            }
            let analysis = builtExpression.algebraAnalysis
            let name = namingService.resolvedExplicitFunctionName(
                from: analysis?.relation,
                existingObjects: context.document.objects
            ) ?? namingService.nextFunctionName(existingObjects: context.document.objects)
            let object = MathObject(
                name: name,
                type: .function,
                expression: builtExpression,
                style: MathStyle(colorToken: nextFunctionColor(existing: context.document.objects))
            )
            return ModuleCommandOutput(
                documentCommands: [.addObject(object)],
                effects: [.selectObject(id: object.id)]
            )

        case .createSegment(let start, let end):
            let names = namingService.nextPointNames(existingObjects: context.document.objects, count: 2)
            let aName = names.first ?? "A"
            let bName = names.dropFirst().first ?? "B"

            let aDisplay = "\(aName) = (\(format(start.x)), \(format(start.y)))"
            let bDisplay = "\(bName) = (\(format(end.x)), \(format(end.y)))"

            let pointA = MathObject(
                name: aName,
                type: .point,
                expression: MathExpression(displayText: aDisplay),
                position: start,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "yellowOrange")
            )
            let pointB = MathObject(
                name: bName,
                type: .point,
                expression: MathExpression(displayText: bDisplay),
                position: end,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "purple")
            )

            let segmentName = namingService.nextSegmentName(existingObjects: context.document.objects)
            let segmentDisplay = "\(segmentName): 线段"
            let segment = MathObject(
                name: segmentName,
                type: .segment,
                expression: MathExpression(displayText: segmentDisplay),
                points: [start, end],
                geometryDefinition: GeometryDefinition(
                    kind: GeometryKind.segment,
                    anchors: [GeometryAnchor.object(pointA.id), GeometryAnchor.object(pointB.id)]
                ),
                style: MathStyle(colorToken: "blue")
            )

            return ModuleCommandOutput(
                documentCommands: [.addObject(pointA), .addObject(pointB), .addObject(segment)],
                effects: [.selectObject(id: segment.id)]
            )

        case .createLine(let pointA, let pointB):
            return createLine(pointA: pointA, pointB: pointB, pointAID: nil, pointBID: nil, context: context)

        case .createRay(let start, let through):
            return createRay(start: start, through: through, startID: nil, throughID: nil, context: context)

        case .updateInputText(_):
            return ModuleCommandOutput()

        case .openInput(_):
            return ModuleCommandOutput()

        case .dismissInput:
            return ModuleCommandOutput()

        case .toggleKeyboard:
            return ModuleCommandOutput()

        case .setKeyboardVisible(_):
            return ModuleCommandOutput()

        case .setInspectorVisible(_):
            return ModuleCommandOutput()

        case .toggleObjectPanel:
            return ModuleCommandOutput()

        case .setObjectPanelVisible(_):
            return ModuleCommandOutput()

        case .moduleSpecific(let id, let payload):
            if id == "plane.createSegmentWithOptionalPoints" {
                return handleCreateSegmentWithOptionalPoints(payload: payload, context: context)
            }
            if id == "plane.createLineWithOptionalPoints" {
                return handleCreateLineWithOptionalPoints(payload: payload, context: context)
            }
            if id == "plane.createRayWithOptionalPoints" {
                return handleCreateRayWithOptionalPoints(payload: payload, context: context)
            }
            if id == "plane.createCircleWithOptionalCenter" {
                return handleCreateCircleWithOptionalCenter(payload: payload, context: context)
            }
            if id == "plane.createArc" {
                return handleCreateArc(payload: payload, context: context)
            }
            if id == "plane.createDerivative" {
                return handleCreateDerivative(payload: payload, context: context)
            }
            if id == "plane.findRoots" {
                return handleFindRoots(payload: payload, context: context)
            }
            if id == "plane.createIntersectionPoints" {
                return handleCreateIntersectionPoints(payload: payload, context: context)
            }
            if id == "plane.createMidpoint" {
                return handleCreateMidpoint(payload: payload, context: context)
            }
            if id == "plane.createParallelLine" {
                return handleCreateDerivedLine(payload: payload, context: context, mode: .parallel)
            }
            if id == "plane.createPerpendicularLine" {
                return handleCreateDerivedLine(payload: payload, context: context, mode: .perpendicular)
            }
            return ModuleCommandOutput()

        case .submitInput:
            let text = context.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return ModuleCommandOutput(effects: [.showError("请输入内容")])
            }

            let built = PlaneExpressionService.buildExpression(from: text, fallbackToExplicitY: true)
            let builtExpression: MathExpression
            switch built {
            case .success(let value):
                builtExpression = value
            case .failure(let error):
                return ModuleCommandOutput(effects: [.showError(error.message)])
            }
            let analysis = builtExpression.algebraAnalysis

            let type: MathObjectType = analysis?.classification.kind == .circle ? .circle : .function
            let name = namingService.resolvedExplicitFunctionName(
                from: analysis?.relation,
                existingObjects: context.document.objects
            ) ?? namingService.nextFunctionName(existingObjects: context.document.objects)
            let object = MathObject(
                name: name,
                type: type,
                expression: builtExpression,
                style: MathStyle(colorToken: type == .circle ? "green" : nextFunctionColor(existing: context.document.objects))
            )
            let summary = analysis?.classification.summary ?? builtExpression.displayText

            return ModuleCommandOutput(
                documentCommands: [.addObject(object)],
                effects: [.selectObject(id: object.id), .showToast("已添加：\(summary)")]
            )

        case .setCanvasViewport(let canvasState):
            return ModuleCommandOutput(documentCommands: [.updateCanvasState(canvasState)])

        case .setCanvasInteracting(_):
            return ModuleCommandOutput()

        case .setObjectDragging:
            return ModuleCommandOutput()

        case .setSpaceCameraState:
            return ModuleCommandOutput()

        case .setSpaceWorkPlane:
            return ModuleCommandOutput()

        case .undo, .redo, .revertToOpenState:
            return ModuleCommandOutput()
        }
    }

    private func nextFunctionColor(existing: [MathObject]) -> String {
        let palette = ["blue", "pink", "green", "yellowOrange", "purple", "indigo"]
        let count = existing.filter { $0.type == .function || $0.type == .circle }.count
        return palette[count % palette.count]
    }

    private func format(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    /// Clean up serializer output for display: remove unnecessary `*` between numbers and identifiers.
    /// e.g. "2*x" → "2x", "2*cos(x)" → "2cos(x)", "-1*x" → "-x"
    private func cleanDisplayText(_ source: String) -> String {
        var result = source
        // Replace "digit*letter" with "digitleter"
        if let regex = try? NSRegularExpression(pattern: "([0-9])\\*\\(?([a-zA-Z])", options: []) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result),
                                                     withTemplate: "$1$2")
        }
        // Replace ")*(" with ")("
        result = result.replacingOccurrences(of: ")*(", with: ")(")
        // Replace "-1*" with "-" when followed by a letter
        if let regex = try? NSRegularExpression(pattern: "-1\\*([a-zA-Z])", options: []) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result),
                                                     withTemplate: "-$1")
        }
        return result
    }

    private func handleCreateSegmentWithOptionalPoints(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(SegmentCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("线段创建数据无效")])
        }

        var commands: [DocumentCommand] = []

        let startPoint: MathObject
        if let pointID = decoded.startPointID,
           let existing = context.document.objects.first(where: { $0.id == pointID && $0.type == .point }) {
            startPoint = existing
        } else {
            let name = namingService.nextPointName(existingObjects: context.document.objects)
            let display = "\(name) = (\(format(decoded.startWorldPoint.x)), \(format(decoded.startWorldPoint.y)))"
            let created = MathObject(
                name: name,
                type: .point,
                expression: MathExpression(displayText: display),
                position: decoded.startWorldPoint,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "yellowOrange")
            )
            startPoint = created
            commands.append(.addObject(created))
        }

        let tempObjects = context.document.objects + commands.compactMap {
            if case .addObject(let object) = $0 { return object }
            return nil
        }

        let endPoint: MathObject
        if let pointID = decoded.endPointID,
           let existing = context.document.objects.first(where: { $0.id == pointID && $0.type == .point }) {
            endPoint = existing
        } else {
            let name = namingService.nextPointName(existingObjects: tempObjects)
            let display = "\(name) = (\(format(decoded.endWorldPoint.x)), \(format(decoded.endWorldPoint.y)))"
            let created = MathObject(
                name: name,
                type: .point,
                expression: MathExpression(displayText: display),
                position: decoded.endWorldPoint,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "purple")
            )
            endPoint = created
            commands.append(.addObject(created))
        }

        let segmentName = namingService.nextSegmentName(existingObjects: context.document.objects)
        let segmentDisplay = "\(segmentName): 线段"
        let segment = MathObject(
            name: segmentName,
            type: .segment,
            expression: MathExpression(displayText: segmentDisplay),
            points: [decoded.startWorldPoint, decoded.endWorldPoint],
            geometryDefinition: GeometryDefinition(
                kind: GeometryKind.segment,
                anchors: [GeometryAnchor.object(startPoint.id), GeometryAnchor.object(endPoint.id)]
            ),
            style: MathStyle(colorToken: "blue")
        )
        commands.append(.addObject(segment))

        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.selectObject(id: segment.id)]
        )
    }

    private func handleCreateCircleWithOptionalCenter(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(CircleCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("圆创建数据无效")])
        }

        let dx = decoded.radiusWorldPoint.x - decoded.centerWorldPoint.x
        let dy = decoded.radiusWorldPoint.y - decoded.centerWorldPoint.y
        let radius = (dx * dx + dy * dy).squareRoot()
        guard radius.isFinite, radius > 0 else {
            return ModuleCommandOutput(effects: [.showError("圆半径必须大于 0")])
        }

        var commands: [DocumentCommand] = []
        let centerPoint: MathObject
        if let centerID = decoded.centerPointID,
           let existing = context.document.objects.first(where: { $0.id == centerID && $0.type == .point }) {
            centerPoint = existing
        } else {
            let centerName = namingService.nextPointName(existingObjects: context.document.objects)
            let display = "\(centerName) = (\(format(decoded.centerWorldPoint.x)), \(format(decoded.centerWorldPoint.y)))"
            let created = MathObject(
                name: centerName,
                type: .point,
                expression: MathExpression(displayText: display),
                position: decoded.centerWorldPoint,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                style: MathStyle(colorToken: "yellowOrange")
            )
            centerPoint = created
            commands.append(.addObject(created))
        }

        let source = "(x-\(format(decoded.centerWorldPoint.x)))^2+(y-\(format(decoded.centerWorldPoint.y)))^2=\(format(radius * radius))"
        let built = PlaneExpressionService.buildExpression(from: source, fallbackToExplicitY: false)
        let expression: MathExpression
        switch built {
        case .success(let value):
            expression = value
        case .failure(let error):
            return ModuleCommandOutput(effects: [.showError(error.message)])
        }

        let throughPoint: MathObject?
        if let throughID = decoded.throughPointID,
           let existing = context.document.objects.first(where: { $0.id == throughID && $0.type == .point }) {
            throughPoint = existing
        } else {
            throughPoint = nil
        }

        let resolvedCenter = centerPoint.position ?? decoded.centerWorldPoint
        let geometryAnchors: [GeometryAnchor]
        let resolvedRadiusPoint: WorldPoint
        let dependency: GeometryDependency
        if let throughPoint {
            resolvedRadiusPoint = throughPoint.position ?? decoded.radiusWorldPoint
            geometryAnchors = [GeometryAnchor.object(centerPoint.id), GeometryAnchor.object(throughPoint.id)]
            dependency = GeometryDependency(
                kind: .circleByCenterPoint(centerPointID: centerPoint.id, throughPointID: throughPoint.id)
            )
        } else {
            resolvedRadiusPoint = WorldPoint(
                x: resolvedCenter.x + radius,
                y: resolvedCenter.y
            )
            geometryAnchors = [GeometryAnchor.object(centerPoint.id), GeometryAnchor.fixedPoint(resolvedRadiusPoint)]
            dependency = GeometryDependency(
                kind: .circleByCenterRadius(centerPointID: centerPoint.id, radius: radius)
            )
        }

        let circleName = namingService.nextCircleName(existingObjects: context.document.objects)
        let circle = MathObject(
            name: circleName,
            type: .circle,
            expression: expression,
            points: [resolvedCenter, resolvedRadiusPoint],
            geometryDefinition: GeometryDefinition(kind: GeometryKind.circle, anchors: geometryAnchors),
            geometryDependency: dependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "green")
        )
        commands.append(.addObject(circle))
        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.selectObject(id: circle.id), .showToast("已创建圆")]
        )
    }

    private func handleCreateArc(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard let data = payload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(PlaneArcCreatePayload.self, from: data) else {
            return ModuleCommandOutput()
        }
        let pointAWorld = decoded.pointAWorldPoint
        let pointBWorld = decoded.pointBWorldPoint
        let pointCWorld = decoded.pointCWorldPoint

        // Validate non-collinear
        guard PlaneGeometryResolver.arcFromThreePoints(pointAWorld, pointBWorld, pointCWorld) != nil else {
            return ModuleCommandOutput(
                effects: [.showToast("三点共线，无法创建圆弧")]
            )
        }

        var commands: [DocumentCommand] = []
        let objectsByID = Dictionary(uniqueKeysWithValues: context.document.objects.map { ($0.id, $0) })

        func resolvePoint(world: WorldPoint, id: UUID?, label: String) -> UUID {
            if let id, objectsByID[id]?.type == .point { return id }
            let point = MathObject(name: label, type: .point, expression: MathExpression(displayText: "(\(world.x), \(world.y))"), position: world, style: MathStyle(colorToken: "blue"))
            commands.append(.addObject(point))
            return point.id
        }

        let labels = namingService.nextPointNames(existingObjects: context.document.objects, count: 3)
        let pointAID = resolvePoint(world: pointAWorld, id: decoded.pointAID, label: labels.indices.contains(0) ? labels[0] : "A")
        let pointBID = resolvePoint(world: pointBWorld, id: decoded.pointBID, label: labels.indices.contains(1) ? labels[1] : "B")
        let pointCID = resolvePoint(world: pointCWorld, id: decoded.pointCID, label: labels.indices.contains(2) ? labels[2] : "C")

        let dependency = GeometryDependency(
            kind: .arcByThreePoints(pointAID: pointAID, pointBID: pointBID, pointCID: pointCID)
        )

        let arcName = namingService.nextArcName(existingObjects: context.document.objects)
        let arc = MathObject(
            name: arcName,
            type: .arc,
            expression: MathExpression(displayText: "圆弧(\(arcName))"),
            points: [pointAWorld, pointBWorld, pointCWorld],
            geometryDependency: dependency,
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "orange")
        )
        commands.append(.addObject(arc))

        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.selectObject(id: arc.id), .showToast("已创建圆弧")]
        )
    }

    private func handleCreateDerivative(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard let data = payload.data(using: .utf8),
              let objectIDString = String(data: data, encoding: .utf8),
              let objectID = UUID(uuidString: objectIDString),
              let sourceObject = context.document.objects.first(where: { $0.id == objectID }),
              sourceObject.type == .function else {
            return ModuleCommandOutput(effects: [.showError("请先选择一个函数对象")])
        }

        // Get the semantic expression via AlgebraAnalysisResult → Expr conversion
        guard let analysis = sourceObject.expression.algebraAnalysis else {
            return ModuleCommandOutput(effects: [.showError("无法解析函数表达式")])
        }

        let sourceAlgebraExpr: AlgebraExpression
        switch analysis.relation {
        case .expression(let expr):
            sourceAlgebraExpr = expr
        case .equation(let eq):
            sourceAlgebraExpr = eq.right
        }

        let sourceExpr = sourceAlgebraExpr.toSemanticExpr()
        let variable = Symbol(name: "x")

        // Differentiate
        guard let derivative = SymbolicDifferentiator.differentiate(sourceExpr, withRespectTo: variable) else {
            return ModuleCommandOutput(effects: [.showError("不支持对该函数求导")])
        }

        // Simplify
        let simplifier = ExpressionSimplifier()
        let simplified = simplifier.simplify(derivative)

        // Serialize using the production serializer (not DebugPrinter)
        let normalizer = ExpressionNormalizer()
        let normalized = normalizer.normalize(simplified)
        guard let serialized = ExprSerializer.serialize(normalized) else {
            return ModuleCommandOutput(effects: [.showError("无法序列化导函数表达式")])
        }

        // Build the derivative expression string
        let sourceName = sourceObject.name
        let displaySource = cleanDisplayText(serialized)
        let derivSource = "y=\(serialized)"

        // Build the MathExpression using PlaneExpressionService
        let built = PlaneExpressionService.buildExpression(from: derivSource, fallbackToExplicitY: true)
        let derivExpression: MathExpression
        switch built {
        case .success(let expr):
            derivExpression = expr
        case .failure:
            derivExpression = MathExpression(displayText: displaySource)
        }

        // Parse derivative order from source name. Strip primes, ^(n), "(x)".
        let noPrimes = sourceName.replacingOccurrences(of: "'", with: "")
        let noArg = noPrimes.replacingOccurrences(of: "(x)", with: "")
        // Strip ^(digits) notation: e.g. f_1^(2)(x) → f_1
        var baseName = noArg
        var parsedOrder = 0
        if let regex = try? NSRegularExpression(pattern: "\\^\\((\\d+)\\)", options: []),
           let match = regex.firstMatch(in: noArg, options: [], range: NSRange(noArg.startIndex..., in: noArg)),
           let range = Range(match.range(at: 1), in: noArg) {
            parsedOrder = Int(noArg[range]) ?? 0
            let endIdx = noArg.index(noArg.startIndex, offsetBy: match.range.location)
            baseName = String(noArg[noArg.startIndex..<endIdx])
        }
        let explicitPrimes = sourceName.filter { $0 == "'" }.count
        let order = explicitPrimes + parsedOrder + 1

        // Format: 1-2 primes, 3+ uses ^(n)
        let derivativeSuffix: String
        if order <= 2 {
            derivativeSuffix = String(repeating: "'", count: order)
        } else {
            derivativeSuffix = "^(\(order))"
        }
        let name = "\(baseName)\(derivativeSuffix)(\(variable.name))"
        let derivObject = MathObject(
            name: name,
            type: .function,
            expression: derivExpression,
            style: MathStyle(colorToken: nextFunctionColor(existing: context.document.objects))
        )

        return ModuleCommandOutput(
            documentCommands: [.addObject(derivObject)],
            effects: [.selectObject(id: derivObject.id), .showToast("已创建导函数 \(name)")]
        )
    }

    /// Find Roots MVP: creates static root points for explicitY functions.
    /// Root points are NOT dynamically linked to the source function (deferred).
    private func handleFindRoots(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard let data = payload.data(using: .utf8),
              let objectIDString = String(data: data, encoding: .utf8),
              let objectID = UUID(uuidString: objectIDString),
              let sourceObject = context.document.objects.first(where: { $0.id == objectID }),
              sourceObject.type == .function else {
            return ModuleCommandOutput(effects: [.showError("请先选择一个函数对象")])
        }

        guard let analysis = sourceObject.expression.algebraAnalysis else {
            return ModuleCommandOutput(effects: [.showError("无法解析函数表达式")])
        }

        let sourceAlgebraExpr: AlgebraExpression
        switch analysis.relation {
        case .expression(let expr): sourceAlgebraExpr = expr
        case .equation(let eq):     sourceAlgebraExpr = eq.right
        }

        let sourceExpr = sourceAlgebraExpr.toSemanticExpr()
        let variable = Symbol(name: "x")
        let equation: Expr = .equation(left: sourceExpr, right: .integer(0))

        let result = EquationSolver.solve(equation, variable: variable)

        if !result.diagnostics.isEmpty {
            let msg = result.diagnostics.map { d in
                switch d {
                case .noRealSolution: return "无实数解"
                case .infiniteSolutions: return "无穷多解"
                case .unsupported(let s): return s
                case .notAUnivariateEquation: return "不是一元方程"
                case .extractionFailed(let s): return s
                case .numericDidNotConverge: return "数值方法未收敛"
                }
            }.joined(separator: "; ")
            return ModuleCommandOutput(effects: [.showToast(msg)])
        }

        var commands: [DocumentCommand] = []
        var usedRootNames = Set(context.document.objects.filter { $0.name.hasPrefix("R_") }.map(\.name))
        func nextRootName() -> String {
            var index = 1
            while usedRootNames.contains("R_\(index)") {
                index += 1
            }
            let name = "R_\(index)"
            usedRootNames.insert(name)
            return name
        }

        for solution in result.solutions {
            let x: Double
            switch solution {
            case .exact(let value):
                let eval = ExprEvaluator().evaluate(value, environment: EvaluationEnvironment())
                if case .value(let v) = eval, v.isFinite { x = v } else { continue }
            case .numeric(let value, _):
                x = value
            }
            let pointName = nextRootName()
            let display = "\(pointName) = (\(format(x)), 0)"
            let point = MathObject(
                name: pointName,
                type: .point,
                expression: MathExpression(displayText: display),
                position: WorldPoint(x: x, y: 0),
                style: MathStyle(colorToken: "red")
            )
            commands.append(.addObject(point))
        }

        if commands.isEmpty {
            return ModuleCommandOutput(effects: [.showToast("未找到实根")])
        }

        // Do NOT auto-select root points — selection triggers keyboard preview pollution.
        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.showToast("已添加 \(commands.count) 个根点")]
        )
    }

    private func handleCreateLineWithOptionalPoints(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(LineCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("直线创建数据无效")])
        }
        return createLine(
            pointA: decoded.pointAWorldPoint,
            pointB: decoded.pointBWorldPoint,
            pointAID: decoded.pointAID,
            pointBID: decoded.pointBID,
            context: context
        )
    }

    private func handleCreateRayWithOptionalPoints(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(RayCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("射线创建数据无效")])
        }
        return createRay(
            start: decoded.startWorldPoint,
            through: decoded.throughWorldPoint,
            startID: decoded.startPointID,
            throughID: decoded.throughPointID,
            context: context
        )
    }

    private func handleCreateIntersectionPoints(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(IntersectionCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("交点创建数据无效")])
        }

        guard decoded.firstObjectID != decoded.secondObjectID else {
            return ModuleCommandOutput()
        }
        guard let firstObject = context.document.objects.first(where: { $0.id == decoded.firstObjectID }),
              let secondObject = context.document.objects.first(where: { $0.id == decoded.secondObjectID }) else {
            return ModuleCommandOutput()
        }

        let allowedTypes: Set<MathObjectType> = [.segment, .line, .ray, .circle]
        guard allowedTypes.contains(firstObject.type), allowedTypes.contains(secondObject.type) else {
            return ModuleCommandOutput()
        }

        let points = PlaneIntersectionPreviewResolver.previewPoints(
            firstObjectID: firstObject.id,
            secondObjectID: secondObject.id,
            objects: context.document.objects
        )
        guard !points.isEmpty else {
            return ModuleCommandOutput(effects: [.showToast("无交点")])
        }

        let supportsDynamicIntersection = supportsDynamicIntersectionType(firstObject.type)
            && supportsDynamicIntersectionType(secondObject.type)

        let names = namingService.nextPointNames(existingObjects: context.document.objects, count: points.count)
        var commands: [DocumentCommand] = []
        var createdIDs: [UUID] = []
        for (index, point) in points.enumerated() {
            let name = names[index]
            let display = "\(name) = (\(format(point.x)), \(format(point.y)))"
            let object = MathObject(
                name: name,
                type: .point,
                expression: MathExpression(displayText: display),
                position: point,
                geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
                geometryDependency: supportsDynamicIntersection
                    ? GeometryDependency(
                        kind: .intersectionOf(
                            objectAID: firstObject.id,
                            objectBID: secondObject.id,
                            index: index
                        )
                    )
                    : nil,
                geometryDefinitionStatus: supportsDynamicIntersection ? .defined : nil,
                style: MathStyle(colorToken: "yellowOrange")
            )
            commands.append(.addObject(object))
            createdIDs.append(object.id)
        }

        let selectEffect: WorkspaceEffect = .selectObject(id: createdIDs.last ?? createdIDs[0])
        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [selectEffect, .showToast("已创建\(points.count)个交点")]
        )
    }

    private func handleCreateMidpoint(
        payload: String,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(MidpointCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("中点创建数据无效")])
        }

        let midpointWorld: WorldPoint?

        var dependency: GeometryDependency?
        if let segmentID = decoded.segmentID {
            guard let segment = context.document.objects.first(where: { $0.id == segmentID && $0.type == .segment && $0.isVisible }),
                  let endpoints = PlaneGeometryResolver.segmentEndpoints(for: segment, in: context.document.objects) else {
                return ModuleCommandOutput()
            }
            midpointWorld = midpoint(of: endpoints.0, and: endpoints.1)
        } else if let pointAID = decoded.pointAID, let pointBID = decoded.pointBID {
            guard pointAID != pointBID else { return ModuleCommandOutput() }
            guard let pointAObject = context.document.objects.first(where: { $0.id == pointAID && $0.type == .point && $0.isVisible }),
                  let pointBObject = context.document.objects.first(where: { $0.id == pointBID && $0.type == .point && $0.isVisible }),
                  let pointA = PlaneGeometryResolver.pointPosition(for: pointAObject),
                  let pointB = PlaneGeometryResolver.pointPosition(for: pointBObject) else {
                return ModuleCommandOutput()
            }
            midpointWorld = midpoint(of: pointA, and: pointB)
            dependency = GeometryDependency(kind: .midpointOfPoints(pointAID: pointAID, pointBID: pointBID))
        } else {
            midpointWorld = nil
        }

        guard let midpointWorld else { return ModuleCommandOutput() }
        let name = namingService.nextPointName(existingObjects: context.document.objects)
        let display = "\(name) = (\(format(midpointWorld.x)), \(format(midpointWorld.y)))"
        let midpointObject = MathObject(
            name: name,
            type: .point,
            expression: MathExpression(displayText: display),
            position: midpointWorld,
            geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
            geometryDependency: dependency,
            geometryDefinitionStatus: dependency == nil ? nil : .defined,
            style: MathStyle(colorToken: "yellowOrange")
        )

        return ModuleCommandOutput(
            documentCommands: [.addObject(midpointObject)],
            effects: [.selectObject(id: midpointObject.id)]
        )
    }

    private enum DerivedLineMode {
        case parallel
        case perpendicular
    }

    private func handleCreateDerivedLine(
        payload: String,
        context: ModuleCommandContext,
        mode: DerivedLineMode
    ) -> ModuleCommandOutput {
        guard
            let data = payload.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(DerivedLineCreatePayload.self, from: data)
        else {
            return ModuleCommandOutput(effects: [.showError("派生直线创建数据无效")])
        }

        guard let referenceObject = context.document.objects.first(where: {
            $0.id == decoded.referenceObjectID && $0.isVisible
        }),
              let pointObject = context.document.objects.first(where: {
                  $0.id == decoded.pointID && $0.type == .point && $0.isVisible
              }) else {
            return ModuleCommandOutput()
        }

        let allowedReferenceTypes: Set<MathObjectType> = [.segment, .line, .ray]
        guard allowedReferenceTypes.contains(referenceObject.type),
              let referencePoints = PlaneGeometryResolver.lineLikePoints(for: referenceObject, in: context.document.objects),
              let throughPoint = PlaneGeometryResolver.pointPosition(for: pointObject) else {
            return ModuleCommandOutput()
        }

        let dx = referencePoints.1.x - referencePoints.0.x
        let dy = referencePoints.1.y - referencePoints.0.y
        let magnitudeSquared = dx * dx + dy * dy
        guard magnitudeSquared > 1e-18, dx.isFinite, dy.isFinite else {
            return ModuleCommandOutput()
        }

        let direction: WorldPoint
        switch mode {
        case .parallel:
            direction = WorldPoint(x: dx, y: dy)
        case .perpendicular:
            direction = WorldPoint(x: -dy, y: dx)
        }
        guard direction.x.isFinite, direction.y.isFinite,
              direction.x * direction.x + direction.y * direction.y > 1e-18 else {
            return ModuleCommandOutput()
        }

        let targetPoint = WorldPoint(
            x: throughPoint.x + direction.x,
            y: throughPoint.y + direction.y
        )
        let dependencyKind: GeometryDependencyKind
        switch mode {
        case .parallel:
            dependencyKind = .parallelLine(referenceObjectID: decoded.referenceObjectID, throughPointID: decoded.pointID)
        case .perpendicular:
            dependencyKind = .perpendicularLine(referenceObjectID: decoded.referenceObjectID, throughPointID: decoded.pointID)
        }
        let name = namingService.nextLineName(existingObjects: context.document.objects)
        let line = MathObject(
            name: name,
            type: .line,
            expression: MathExpression(displayText: "\(name): 直线"),
            points: [throughPoint, targetPoint],
            geometryDefinition: GeometryDefinition(
                kind: GeometryKind.line,
                anchors: [
                    GeometryAnchor.object(decoded.pointID),
                    GeometryAnchor.fixedPoint(targetPoint)
                ]
            ),
            geometryDependency: GeometryDependency(kind: dependencyKind),
            geometryDefinitionStatus: .defined,
            style: MathStyle(colorToken: "indigo")
        )
        return ModuleCommandOutput(
            documentCommands: [.addObject(line)],
            effects: [.selectObject(id: line.id)]
        )
    }

    private func createLine(
        pointA: WorldPoint,
        pointB: WorldPoint,
        pointAID: UUID?,
        pointBID: UUID?,
        geometryDependency: GeometryDependency? = nil,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard squaredDistance(pointA, pointB) > 1e-18 else {
            return ModuleCommandOutput(effects: [.showError("两点过近，无法创建直线")])
        }

        var commands: [DocumentCommand] = []
        let firstPoint = resolveConstructionPoint(
            requestedID: pointAID,
            fallbackWorldPoint: pointA,
            existingColorToken: "yellowOrange",
            existingObjects: context.document.objects,
            pendingCommands: &commands
        )
        let currentObjects = context.document.objects + commands.compactMap {
            if case .addObject(let object) = $0 { return object }
            return nil
        }
        let secondPoint = resolveConstructionPoint(
            requestedID: pointBID,
            fallbackWorldPoint: pointB,
            existingColorToken: "purple",
            existingObjects: currentObjects,
            pendingCommands: &commands
        )

        let name = namingService.nextLineName(existingObjects: context.document.objects)
        let line = MathObject(
            name: name,
            type: .line,
            expression: MathExpression(displayText: "\(name): 直线"),
            points: [pointA, pointB],
            geometryDefinition: GeometryDefinition(
                kind: GeometryKind.line,
                anchors: [GeometryAnchor.object(firstPoint.id), GeometryAnchor.object(secondPoint.id)]
            ),
            geometryDependency: geometryDependency,
            geometryDefinitionStatus: geometryDependency == nil ? nil : .defined,
            style: MathStyle(colorToken: "indigo")
        )
        commands.append(.addObject(line))
        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.selectObject(id: line.id)]
        )
    }

    private func createRay(
        start: WorldPoint,
        through: WorldPoint,
        startID: UUID?,
        throughID: UUID?,
        context: ModuleCommandContext
    ) -> ModuleCommandOutput {
        guard squaredDistance(start, through) > 1e-18 else {
            return ModuleCommandOutput(effects: [.showError("两点过近，无法创建射线")])
        }

        var commands: [DocumentCommand] = []
        let startPoint = resolveConstructionPoint(
            requestedID: startID,
            fallbackWorldPoint: start,
            existingColorToken: "yellowOrange",
            existingObjects: context.document.objects,
            pendingCommands: &commands
        )
        let currentObjects = context.document.objects + commands.compactMap {
            if case .addObject(let object) = $0 { return object }
            return nil
        }
        let directionPoint = resolveConstructionPoint(
            requestedID: throughID,
            fallbackWorldPoint: through,
            existingColorToken: "purple",
            existingObjects: currentObjects,
            pendingCommands: &commands
        )

        let name = namingService.nextRayName(existingObjects: context.document.objects)
        let ray = MathObject(
            name: name,
            type: .ray,
            expression: MathExpression(displayText: "\(name): 射线"),
            points: [start, through],
            geometryDefinition: GeometryDefinition(
                kind: GeometryKind.ray,
                anchors: [GeometryAnchor.object(startPoint.id), GeometryAnchor.object(directionPoint.id)]
            ),
            style: MathStyle(colorToken: "pink")
        )
        commands.append(.addObject(ray))
        return ModuleCommandOutput(
            documentCommands: commands,
            effects: [.selectObject(id: ray.id)]
        )
    }

    private func resolveConstructionPoint(
        requestedID: UUID?,
        fallbackWorldPoint: WorldPoint,
        existingColorToken: String,
        existingObjects: [MathObject],
        pendingCommands: inout [DocumentCommand]
    ) -> MathObject {
        if let requestedID,
           let existing = existingObjects.first(where: { $0.id == requestedID && $0.type == .point }) {
            return existing
        }
        let name = namingService.nextPointName(existingObjects: existingObjects)
        let display = "\(name) = (\(format(fallbackWorldPoint.x)), \(format(fallbackWorldPoint.y)))"
        let created = MathObject(
            name: name,
            type: .point,
            expression: MathExpression(displayText: display),
            position: fallbackWorldPoint,
            geometryDefinition: GeometryDefinition(kind: GeometryKind.point, anchors: []),
            style: MathStyle(colorToken: existingColorToken)
        )
        pendingCommands.append(.addObject(created))
        return created
    }

    private func squaredDistance(_ a: WorldPoint, _ b: WorldPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return dx * dx + dy * dy
    }

    private func midpoint(of a: WorldPoint, and b: WorldPoint) -> WorldPoint {
        WorldPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }

    private func isLineLike(_ type: MathObjectType) -> Bool {
        switch type {
        case .segment, .line, .ray, .arc:
            return true
        case .circle, .function, .point, .parameter, .parameterGroup, .arc:
            return false
        }
    }

    private func supportsDynamicIntersectionType(_ type: MathObjectType) -> Bool {
        switch type {
        case .segment, .line, .ray, .circle:
            return true
        case .function, .point, .parameter, .parameterGroup, .arc:
            return false
        }
    }

}

private struct SegmentCreatePayload: Codable {
    let startPointID: UUID?
    let startWorldPoint: WorldPoint
    let endPointID: UUID?
    let endWorldPoint: WorldPoint
}

struct CircleCreatePayload: Codable {
    let centerPointID: UUID?
    let throughPointID: UUID?
    let centerWorldPoint: WorldPoint
    let radiusWorldPoint: WorldPoint
}

struct PlaneArcCreatePayload: Codable {
    let pointAID: UUID?
    let pointAWorldPoint: WorldPoint
    let pointBID: UUID?
    let pointBWorldPoint: WorldPoint
    let pointCID: UUID?
    let pointCWorldPoint: WorldPoint
}

private struct LineCreatePayload: Codable {
    let pointAID: UUID?
    let pointAWorldPoint: WorldPoint
    let pointBID: UUID?
    let pointBWorldPoint: WorldPoint
}

private struct RayCreatePayload: Codable {
    let startPointID: UUID?
    let startWorldPoint: WorldPoint
    let throughPointID: UUID?
    let throughWorldPoint: WorldPoint
}

private struct IntersectionCreatePayload: Codable {
    let firstObjectID: UUID
    let secondObjectID: UUID
}

private struct MidpointCreatePayload: Codable {
    let segmentID: UUID?
    let pointAID: UUID?
    let pointBID: UUID?
}

private struct DerivedLineCreatePayload: Codable {
    let referenceObjectID: UUID
    let pointID: UUID
}
