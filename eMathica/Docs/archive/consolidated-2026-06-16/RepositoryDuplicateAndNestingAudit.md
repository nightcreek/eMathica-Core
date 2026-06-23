# Repository Duplicate and Nesting Audit

> **日期:** 2026-06-16
> **模式:** 只读审计
> **审计范围:** eMathica/, eMathicaTests/, Tests/, Packages/, Resources/, Docs/, Scripts/

---

## 1. Duplicate Source Files

### 1.1 GeometryDefinition.swift — 跨 Package 重复

| 文件名 | 路径 A | 路径 B | 是否内容相同 | 是否合理 | 建议 |
|--------|--------|--------|------------|---------|------|
| `GeometryDefinition.swift` | `DocumentSystem/GeometryDefinition.swift` | `Packages/EMathicaMathCore/Sources/EMathicaMathCore/GeometryDefinition.swift` | 否（缺少 `arc` case，无 `public`，无 `Sendable`） | 否 | 历史迁移残留，DocumentSystem 导入了 EMathicaMathCore 但保留了内部副本。**建议 Plane v1.0 后删除 DocumentSystem 中的副本**，确认所有引用都通过 Package 使用 |

**分析:**

- **Package 版本** (`EMathicaMathCore`): `public enum GeometryKind`，包含 `arc` case，遵循 `Sendable`
- **DocumentSystem 版本**: `enum GeometryKind`（无访问修饰符，等效 `internal`），**缺少 `arc` case**，无 `Sendable`
- DocumentSystem 版本通过 `import EMathicaMathCore` 使用 Package 的类型，但保留了内部副本
- 这是 Package 化过程中的历史残留 — 早期 EMathicaMathCore 未完善时 DocumentSystem 自包含了一份拷贝

**代码对比摘要:**

```swift
// Package 版本 (public)
public enum GeometryKind: String, Codable, Equatable, Hashable, Sendable {
    case point, segment, line, ray, circle, arc, point3D, segment3D, line3D, plane3D
}

// DocumentSystem 版本 (internal，缺少 arc)
enum GeometryKind: String, Codable, Equatable, Hashable {
    case point, segment, line, ray, circle, point3D, segment3D, line3D, plane3D
}
```

**风险评估:** 当前 DocumentSystem 副本缺少 `arc` case，如代码中有使用 `GeometryKind.arc` 的路径，会编译失败。但 DocumentSystem 导入了完整的 Package，因此实际运行时不依赖这个内部副本。

---

### 1.2 其他同名文件检查

通过 Glob 扫描全项目，未发现其他同名 Swift 文件存在于不同路径的情况。

---

## 2. Duplicate Test Files

### 2.1 App Target Tests vs Package Tests — 5 个文件同名

| 文件名 | App Target (eMathicaTests/) | Package (EMathicaMathCoreTests/) | 测试相同类型 | 是否合理 | 建议 |
|--------|---------------------------|--------------------------------|------------|---------|------|
| `CASCoreTests.swift` | ✅ 存在 | ✅ 存在 | 是 | 基本合理 | App 版本额外引用 DocumentKit/WorkspaceKit；Package 版本为纯单元测试 |
| `ConditionEvaluatorTests.swift` | ✅ 存在 | ✅ 存在 | 是 | 基本合理 | 同上 |
| `EvaluationCoreTests.swift` | ✅ 存在 | ✅ 存在 | 是 | 基本合理 | 同上 |
| `GraphCoreTests.swift` | ✅ 存在 | ✅ 存在 | 是 | 基本合理 | 同上 |
| `SamplingCoreTests.swift` | ✅ 存在 (2113 行) | ✅ 存在 (2485 行) | 是 | 基本合理 | Package 版本更全面（额外 slider/environment 测试）；App 版本涉及跨 Package 集成 |

**分析:**

- 两者测试目标相同（`ExplicitFunctionSampler2D`, `GraphIntentSampler2D`, `ParametricCurveSampler2D`, `ImplicitCurveSampler2D`, `ConicSampler2D`, `PolarCurveSampler2D`, `PrimitiveSampler2D`, `PiecewiseSampler2D`, `SegmentStitcher2D`）
- Package 测试套件更独立、更全面（2485 行 vs 2113 行）
- App 测试套件额外 `@testable import EMathicaWorkspaceKit` 和 `EMathicaDocumentKit`，做集成验证
- **不存在危险级重复** — 两个测试套件服务不同目的（单元测试 vs 集成测试）

**建议:** 保持现状。Plane v1.0 后可考虑让 App Target 测试委托给 Package 测试以减少维护成本。

---

## 3. Duplicate Resource Files

### 3.1 模块图标资源重复 — PNG+SVG vs PNG-only

| 资源名 | emathica_module_icons/ (PNG+SVG) | *.imageset/ (PNG only) | 是否内容相同 | 是否被引用 | 是否可删 |
|--------|-------------------------------|----------------------|------------|---------|------|
| `data_analysis` | ✅ PNG + SVG | ✅ PNG | PNG 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |
| `modeling` | ✅ PNG + SVG | ✅ PNG | PNG 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |
| `music` | ✅ PNG + SVG | ✅ PNG | PNG 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |
| `notes_formula` | ✅ PNG + SVG | ✅ PNG | PNG 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |
| `plane_calculator` | ✅ PNG + SVG | ✅ PNG | PNG 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |
| `space_calculator` | ✅ PNG + SVG | ✅ PNG | 相同 | Xcode Asset Catalog | **SVG 可删，保留 imageset** |

**分析:**

- `emathica_module_icons/` 是遗留的非标准 Asset Catalog 目录，直接存放 PNG 和 SVG 文件
- `*.imageset/` 是 Xcode 标准 Asset Catalog 格式，通过 `Contents.json` 引用
- Xcode Build 时使用 `*.imageset/` 中的资源；`emathica_module_icons/` 中的文件**未被正式引用**
- 当前 `.imageset/` 中的 PNG 已足够，无需 SVG 版本

**⚠️ 重要警告:** 不允许直接删除资源。必须先通过 Xcode Asset Catalog 和代码搜索确认无引用后，在 Plane v1.0 后作为清理任务处理。

**建议:**
1. **暂不动** — 当前 Architecture Freeze 期间禁止删除
2. Plane v1.0 后将 `emathica_module_icons/` 中的 SVG 文件移入对应 `.imageset/` 目录（或按需转换）
3. 如果 Xcode 不使用 `emathica_module_icons/`，可安全删除整个目录

---

## 4. Build Artifact Audit

| 路径 | 类型 | 是否应纳入 git | 建议 |
|------|------|--------------|------|
| `Packages/EMathicaMathCore/.build/` | SwiftPM 构建缓存 | ❌ 否 | **应加入 .gitignore** |
| `Packages/EMathicaMathCore/.build/arm64-apple-macosx/debug/description.json` | 构建产物 | ❌ 否 | 同上 |
| `Packages/EMathicaMathCore/.build/.lock` | 锁文件 | ❌ 否 | 同上 |
| `Packages/EMathicaMathCore/.build/build.db` | 构建数据库 | ❌ 否 | 同上 |
| `Packages/EMathicaMathCore/.build/debug.yaml` | 构建配置 | ❌ 否 | 同上 |
| `Packages/EMathicaMathCore/.build/plugin-tools.yaml` | 插件工具 | ❌ 否 | 同上 |
| `Packages/EMathicaMathCore/.build/workspace-state.json` | 工作区状态 | ❌ 否 | 同上 |
| `eMathica.xcodeproj/project.xcworkspace/xcuserdata/night_creek.xcuserdatad/UserInterfaceState.xcuserstate` | Xcode 用户状态 | ❌ 否 | **应加入 .gitignore** |

### 4.1 .gitignore 缺失问题

**项目中不存在 `.gitignore` 文件。**

以下内容应被纳入 `.gitignore`（如果重建 git 时）:

```
# SwiftPM
Packages/*.xcodeproj
Packages/*/.build/
Packages/*/.swiftpm/

# Xcode
*.xcuserstate
*.xcuserdatad/
**/UserInterfaceState.xcuserstate
**/xcuserdata/

# macOS
.DS_Store
__MACOSX/

# DerivedData
DerivedData/
```

---

## 5. Meaningless Nesting Audit

### 5.1 嵌套结构分析

| 路径 | 嵌套类型 | 是否合理 | 原因 | 建议 |
|------|---------|---------|------|------|
| `eMathica/eMathica/eMathica/eMathica/eMathica/` | 5 层目录嵌套 | ✅ Architecture Freeze | 历史Xcode项目结构限制，标记为禁止修改 | **禁止触碰** |
| `Tests/GoldenFixtures/Plane/...` | 测试固件目录 | ✅ 合理 | Golden fixture 测试是标准实践，目录结构语义清晰 | 无需调整 |
| `Resources/Assets.xcassets/...` | Xcode 标准结构 | ✅ 合理 | Apple 标准 Asset Catalog 格式 | 无需调整 |
| `Packages/EMathicaMathCore/Sources/EMathicaMathCore/...` | SwiftPM 标准结构 | ✅ 合理 | Swift Package Manager 标准 Source 布局 | 无需调整 |
| `DocumentSystem/Package/` | 子目录 | ✅ 合理 | Package 相关codec和layout定义放在一起 | 无需调整 |
| `CalculatorModules/Plane/Services/` | 功能性子目录 | ✅ 合理 | 按功能组织的服务层 | 无需调整 |
| `eMathica/eMathica/eMathica/eMathica/eMathica/eMathica/Docs/ArchitectureCleanupAudit.md` | 6 层深嵌套 Docs | ⚠️ 异常 | 此文档应在 Source Root 的 Docs/ 而非嵌套子目录中 | **建议 Plane v1.0 后移至 `Docs/`** |
| `CoreHome/Background/` | 功能性子目录 | ✅ 合理 | 背景渲染相关代码分组 | 无需调整 |
| `CoreHome/Layout/` | 功能性子目录 | ✅ 合理 | 响应式布局配置分组 | 无需调整 |

### 5.2 Architecture Freeze 分析

以下路径属于 **Architecture Freeze 范围，禁止任何修改:**

- `eMathica/eMathica/eMathica/eMathica/eMathica/` （5层嵌套 Source Root）
- `Packages/EMathicaMathCore/` （Package 路径冻结）
- `fileSystemSynchronizedGroups` 配置项
- `EXCLUDED_SOURCE_FILE_NAMES` 配置项

---

## 6. Docs Duplication Audit

### 6.1 archive/ vs 当前文档对比

| 文档 | archive/ 版本 | 当前 Docs/ 版本 | 状态 | 是否重复 | 是否过时 | 建议 |
|------|-------------|---------------|------|---------|---------|------|
| `PlaneCalculatorStabilizationStatus.md` | ✅ 存在 | ❌ 不存在 | 已归档 | 是（旧状态文档） | 是 | 保持 archive/；无需恢复 |
| `WorkspaceKitBoundaryFollowupAudit.md` | ❌ 不存在 | ❌ 目录列表中有但文件不存在 | **文件异常** | 未知 | 未知 | **需人工确认文件状态** |
| `RepositoryLayoutAudit.md` | ❌ 不存在 | ✅ 存在 | 当前有效 | 否 | 部分过时（2026-06-06） | 考虑与本次审计合并或归档 |
| `ArchitectureCleanupAudit.md` | ❌ 不存在 | ✅ 仅在嵌套路径 `eMathica/eMathica/eMathica/eMathica/eMathica/eMathica/Docs/` | 位置异常 | 是（应位于 Source Root Docs/） | 否 | **建议移至 Source Root Docs/** |
| `RepositoryCleanupImplementationPlan.md` | ❌ 不存在 | ✅ 存在于 Source Root Docs/ | 当前有效 | 否 | 否 | 保持 |
| `EMathicaArchitectureFreezeStatus.md` | ❌ 不存在 | ✅ 存在 | 当前有效 | 否 | 否 | 保持 |

### 6.2 Docs/archive/ 内容分析

**archive/deprecated-scripts/:**
- `check_mathcore_package_sync.sh` — 已废弃
- `sync_mathcore_to_package.sh` — 已废弃

**archive/ 中包含 27 个历史状态/审计文档**，按主题分类:
- Plane 状态文档（~15个）：反映 Plane 各阶段开发状态
- Space 状态文档（~5个）：Space v0.1 相关
- 其他设计/审计文档（~7个）：Keyboard, MathCore, Sampling 等

**建议:** archive/ 内容属于历史记录，**不建议在 Architecture Freeze 期间移动或删除**。Plane v1.0 后可整体 review 是否需要精简。

---

## 7. Final Classification

### Can remove safely after confirmation

| 路径/文件 | 原因 | 前置条件 |
|---------|------|---------|
| `Packages/EMathicaMathCore/.build/` | SwiftPM 构建缓存，不应进入 git | 创建 .gitignore 后确认 |
| `eMathica.xcodeproj/.../UserInterfaceState.xcuserstate` | Xcode 用户状态文件 | 创建 .gitignore 后确认 |

### Should keep

| 路径/文件 | 原因 |
|---------|------|
| `DocumentSystem/GeometryDefinition.swift` | 历史迁移残留但仍有潜在引用，需人工确认 |
| 5 个重复测试文件 (eMathicaTests/ + EMathicaMathCoreTests/) | 服务不同测试目的（单元 vs 集成） |
| `Tests/GoldenFixtures/Plane/` | Golden fixture 测试标准实践 |
| 所有 archive/ 文档 | 历史记录，Architecture Freeze 期间不动 |

### Should archive

| 路径/文件 | 原因 |
|---------|------|
| `RepositoryLayoutAudit.md` | 日期 2026-06-06，Plane v1.0 前已过时，可归档 |
| `emathica_module_icons/` 中的 SVG 文件 | 未被 Asset Catalog 正式引用，PNG 版本已足够 |

### Needs manual verification in Xcode

| 路径/文件 | 验证内容 |
|---------|---------|
| `emathica_module_icons/` 整体目录 | 确认 Xcode Asset Catalog 是否引用这些文件 |
| `DocumentSystem/GeometryDefinition.swift` | 确认代码中是否有直接引用（而非通过 Package 导入） |
| `WorkspaceKitBoundaryFollowupAudit.md` | 确认文件是否实际存在（目录列表与文件系统不一致） |

### Must not touch because Architecture Freeze

| 路径/文件 | 原因 |
|---------|------|
| `eMathica/eMathica/eMathica/eMathica/eMathica/` | 5层嵌套 Source Root 冻结 |
| `Packages/EMathicaMathCore/Sources/EMathicaMathCore/` | Package 内部结构冻结 |
| `fileSystemSynchronizedGroups` | pbxproj 配置冻结 |
| `EXCLUDED_SOURCE_FILE_NAMES` | pbxproj 配置冻结 |
| `Packages/EMathicaMathCore/Package.swift` | Package 配置冻结 |

---

## 8. Final Recommendation

### 8.1 当前有没有危险级重复文件？

**否。** 未发现危险级重复。

- `GeometryDefinition.swift` 的两个版本内容有差异（Package版本多 `arc` case），但 DocumentSystem 导入了完整 Package，不影响运行
- 测试文件重复是合理的单元测试 vs 集成测试分层
- 资源重复（SVG）不影响编译

### 8.2 当前有没有可立即加入 .gitignore 的内容？

**是。** 以下内容应加入 `.gitignore`（如果重建 git）:

```
# SwiftPM Build
Packages/*/.build/
Packages/*/.swiftpm/

# Xcode User Data
*.xcuserstate
**/xcuserdata/
**/UserInterfaceState.xcuserstate

# macOS System
.DS_Store
__MACOSX/
```

> ⚠️ 当前项目没有 `.gitignore` 文件，建议在安全时创建。

### 8.3 当前有没有应删除的资源重复？

**有，但暂不动。**

- `emathica_module_icons/` 中的 6 个 SVG 文件是 PNG 的冗余副本
- **禁止在 Architecture Freeze 期间删除**
- 需先在 Xcode 中确认 Asset Catalog 引用关系后，Plane v1.0 后清理

### 8.4 当前有没有无意义嵌套？

**除以下两点外，基本无无意义嵌套:**

1. **5层 `eMathica/` 嵌套** — Architecture Freeze，**禁止触碰**
2. **`eMathica/eMathica/eMathica/eMathica/eMathica/eMathica/Docs/ArchitectureCleanupAudit.md`** — 此文档应位于 Source Root 的 `Docs/`，而非嵌套子目录中，但 Plane v1.0 前不应移动

其余嵌套结构（GoldenFixtures, Assets.xcassets, SwiftPM 标准结构）均合理。

### 8.5 哪些内容必须等 Plane v1.0 后再整理？

以下清理任务应推迟到 Plane v1.0 稳定后执行:

| 清理项 | 优先级 | 原因 |
|-------|-------|------|
| 删除 `DocumentSystem/GeometryDefinition.swift` 历史副本 | 中 | 需人工确认无直接本地引用 |
| 清理 `emathica_module_icons/` 中未引用的 SVG | 高 | 需 Xcode Asset Catalog 验证 |
| 将 `ArchitectureCleanupAudit.md` 移至 Source Root Docs/ | 低 | 文档位置异常但不影响功能 |
| Review `archive/` 历史文档是否需要精简 | 低 | 历史记录，保持现状风险低 |
| 考虑 eMathicaTests 是否可委托部分测试给 Package | 低 | 长期维护性优化 |

---

## 附录: 审计执行记录

- **审计时间:** 2026-06-16
- **审计工具:** Glob, Grep, Read, LS
- **审计模式:** 只读（无文件修改）
- **执行限制:** 无 pbxproj 修改，无 Package.swift 修改，无源文件删除/移动
