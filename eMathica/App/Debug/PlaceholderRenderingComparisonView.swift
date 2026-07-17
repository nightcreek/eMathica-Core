import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

struct PlaceholderRenderingComparisonView: View {
    private static let cases: [PlaceholderRenderingComparisonCase] = [
        .placeholder(
            title: "空上标",
            rawMarkup: #"x^{\placeholder{}}"#,
            controlMarkup: #"x^{\quad}"#,
            productionDocument: .init(
                root: .superscript(
                    base: .text("x", role: .symbol),
                    exponent: .placeholder(.init(id: "placeholder:superscript", sourcePath: ["superscript"], fieldIdentity: "superscript", kind: "superscript"))
                )
            )
        ),
        .placeholder(
            title: "空下标",
            rawMarkup: #"x_{\placeholder{}}"#,
            controlMarkup: #"x_{\quad}"#,
            productionDocument: .init(
                root: .subscript(
                    base: .text("x", role: .symbol),
                    subscriptNode: .placeholder(.init(id: "placeholder:subscript", sourcePath: ["subscript"], fieldIdentity: "subscript", kind: "subscript"))
                )
            )
        ),
        .placeholder(
            title: "空根号",
            rawMarkup: #"\sqrt{\placeholder{}}"#,
            controlMarkup: #"\sqrt{\quad}"#,
            productionDocument: .init(
                root: .sqrt(
                    radicand: .placeholder(.init(id: "placeholder:radical", sourcePath: ["radical"], fieldIdentity: "radical", kind: "radical"))
                )
            )
        ),
        .placeholder(
            title: "空分子",
            rawMarkup: #"\frac{\placeholder{}}{y}"#,
            controlMarkup: #"\frac{\quad}{y}"#,
            productionDocument: .init(
                root: .fraction(
                    numerator: .placeholder(.init(id: "placeholder:numerator", sourcePath: ["numerator"], fieldIdentity: "numerator", kind: "numerator")),
                    denominator: .text("y", role: .symbol)
                )
            )
        ),
        .placeholder(
            title: "空分母",
            rawMarkup: #"\frac{x}{\placeholder{}}"#,
            controlMarkup: #"\frac{x}{\quad}"#,
            productionDocument: .init(
                root: .fraction(
                    numerator: .text("x", role: .symbol),
                    denominator: .placeholder(.init(id: "placeholder:denominator", sourcePath: ["denominator"], fieldIdentity: "denominator", kind: "denominator"))
                )
            )
        ),
        .placeholder(
            title: "空括号",
            rawMarkup: #"\left(\placeholder{}\right)"#,
            controlMarkup: #"\left(\quad\right)"#,
            productionDocument: .init(
                root: .parentheses(
                    content: .placeholder(.init(id: "placeholder:content", sourcePath: ["content"], fieldIdentity: "content", kind: "content"))
                )
            )
        ),
        .placeholder(
            title: "嵌套不完整结构",
            rawMarkup: #"\sqrt{x^{\placeholder{}}}"#,
            controlMarkup: #"\sqrt{x^{\quad}}"#,
            productionDocument: .init(
                root: .sqrt(
                    radicand: .superscript(
                        base: .text("x", role: .symbol),
                        exponent: .placeholder(.init(id: "placeholder:nested", sourcePath: ["nested"], fieldIdentity: "nested", kind: "nested"))
                    )
                )
            )
        ),
        .placeholder(
            title: "长公式对照",
            rawMarkup: #"x^2+\sqrt{x}+xxxxxxxx+x^{\placeholder{}}"#,
            controlMarkup: #"x^2+\sqrt{x}+xxxxxxxx+x^{\quad}"#,
            productionDocument: .init(
                root: .sequence([
                    .superscript(base: .text("x", role: .symbol), exponent: .text("2", role: .number)),
                    .operatorSymbol("+"),
                    .sqrt(radicand: .text("x", role: .symbol)),
                    .operatorSymbol("+"),
                    .text("xxxxxxxx", role: .symbol),
                    .operatorSymbol("+"),
                    .superscript(
                        base: .text("x", role: .symbol),
                        exponent: .placeholder(.init(id: "placeholder:long", sourcePath: ["long"], fieldIdentity: "long", kind: "long"))
                    )
                ])
            )
        ),
        .cursor(
            title: "Cursor 对照",
            mediumMarkup: #"x^{\:}"#,
            thickMarkup: #"x^{\;}"#,
            productionDocument: .init(
                root: .superscript(
                    base: .text("x", role: .symbol),
                    exponent: .cursor(.init(id: "cursor:production", sourcePath: ["production"], fieldIdentity: "production", offset: 0, spacingPolicy: .medium))
                )
            )
        )
    ]

    private static let fontSizes: [PlaceholderRenderingComparisonFontSize] = [.small, .medium, .large]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard
                    ForEach(Self.cases) { testCase in
                        PlaceholderRenderingComparisonCaseSection(
                            testCase: testCase,
                            fontSizes: Self.fontSizes
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Placeholder Rendering Comparison")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("同链路对照")
                .font(.headline)
            Text("所有卡片都经过 FormulaDisplayView -> FormulaDisplay resolver -> SwiftMath adapter -> SwiftMath。placeholder 组展示旧 raw 失败、\\quad 控制组和新 production lowering；cursor 组展示 \\:、\\; 和当前 production spacing。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("font role: standard (XITS Math) | backend: swiftMath | production placeholder: quad-like | production cursor: medium-space")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PlaceholderRenderingComparisonCaseSection: View {
    let testCase: PlaceholderRenderingComparisonCase
    let fontSizes: [PlaceholderRenderingComparisonFontSize]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(testCase.title)
                .font(.title3.weight(.semibold))

            ForEach(fontSizes) { size in
                VStack(alignment: .leading, spacing: 12) {
                    Text(size.label)
                        .font(.headline)

                    ForEach(testCase.variants) { variant in
                        comparisonCard(
                            variant: variant,
                            fontSize: size.value
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func comparisonCard(
        variant: PlaceholderRenderingComparisonVariant,
        fontSize: CGFloat
    ) -> some View {
        let diagnostics = PlaceholderRenderingComparisonDiagnostics.measure(
            source: variant.source,
            fontSize: fontSize,
            showsCursor: variant.showsCursor
        )

        VStack(alignment: .leading, spacing: 10) {
            Text(variant.label)
                .font(.subheadline.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                renderView(for: variant, fontSize: fontSize)
                    .fixedSize()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(variant.source.debugDescription)
                .font(.footnote.monospaced())
                .textSelection(.enabled)

            Text(diagnostics.summary)
                .font(.footnote.monospaced())
                .foregroundStyle(diagnostics.isSuccess ? Color.secondary : Color.red)
        }
    }

    @ViewBuilder
    private func renderView(for variant: PlaceholderRenderingComparisonVariant, fontSize: CGFloat) -> some View {
        switch variant.source {
        case .markup(let markup):
            FormulaDisplayView(
                markup: .init(rawValue: markup),
                style: style(fontSize: fontSize),
                options: .init(
                    debugFramesEnabled: false,
                    cursorVisible: variant.showsCursor,
                    renderingBackend: .swiftMath,
                    fontRole: .standard
                ),
                metrics: .init(baseFontSize: fontSize)
            )
        case .document(let document):
            FormulaDisplayView(
                document: document,
                style: style(fontSize: fontSize),
                options: .init(
                    debugFramesEnabled: false,
                    cursorVisible: variant.showsCursor,
                    renderingBackend: .swiftMath,
                    fontRole: .standard
                ),
                metrics: .init(baseFontSize: fontSize)
            )
        }
    }

    private func style(fontSize: CGFloat) -> FormulaDisplayStyle {
        .init(
            textColor: .primary,
            operatorColor: .primary,
            functionColor: .primary,
            rawTextColor: .primary,
            errorTextColor: .red,
            cursorColor: .accentColor,
            placeholderStrokeColor: .secondary,
            placeholderFillColor: .clear,
            fractionLineColor: .primary,
            radicalColor: .primary,
            delimiterColor: .primary,
            debugColor: .clear,
            baseFont: .system(size: fontSize),
            scriptScale: FormulaLayoutMetrics.default.scriptScale
        )
    }
}

private struct PlaceholderRenderingComparisonCase: Identifiable {
    let id = UUID()
    let title: String
    let variants: [PlaceholderRenderingComparisonVariant]

    static func placeholder(
        title: String,
        rawMarkup: String,
        controlMarkup: String,
        productionDocument: FormulaDisplayDocument
    ) -> Self {
        .init(
            title: title,
            variants: [
                .init(label: "raw \\placeholder{} (expected failure)", source: .markup(rawMarkup), showsCursor: false),
                .init(label: #"raw \quad control"#, source: .markup(controlMarkup), showsCursor: false),
                .init(label: "production lowering", source: .document(productionDocument), showsCursor: false)
            ]
        )
    }

    static func cursor(
        title: String,
        mediumMarkup: String,
        thickMarkup: String,
        productionDocument: FormulaDisplayDocument
    ) -> Self {
        .init(
            title: title,
            variants: [
                .init(label: #"raw \: control"#, source: .markup(mediumMarkup), showsCursor: false),
                .init(label: #"raw \; control"#, source: .markup(thickMarkup), showsCursor: false),
                .init(label: "production lowering", source: .document(productionDocument), showsCursor: true)
            ]
        )
    }
}

private struct PlaceholderRenderingComparisonVariant: Identifiable {
    let id = UUID()
    let label: String
    let source: PlaceholderRenderingComparisonSource
    let showsCursor: Bool
}

private enum PlaceholderRenderingComparisonSource {
    case markup(String)
    case document(FormulaDisplayDocument)

    var debugDescription: String {
        switch self {
        case .markup(let markup):
            return markup
        case .document(let document):
            return "document: " + FormulaDisplayDocumentSerializer.serialize(document)
        }
    }
}

private enum PlaceholderRenderingComparisonFontSize: CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { label }

    var label: String {
        switch self {
        case .small:
            return "Small 16"
        case .medium:
            return "Medium 24"
        case .large:
            return "Large 36"
        }
    }

    var value: CGFloat {
        switch self {
        case .small:
            return 16
        case .medium:
            return 24
        case .large:
            return 36
        }
    }
}

private struct PlaceholderRenderingComparisonDiagnostics {
    let isSuccess: Bool
    let summary: String

    static func measure(
        source: PlaceholderRenderingComparisonSource,
        fontSize: CGFloat,
        showsCursor: Bool
    ) -> PlaceholderRenderingComparisonDiagnostics {
        let options = FormulaDisplayOptions(
            debugFramesEnabled: false,
            cursorVisible: showsCursor,
            renderingBackend: .swiftMath,
            fontRole: .standard
        )
        let metrics = FormulaLayoutMetrics(baseFontSize: fontSize)

        let result: FormulaReadOnlyRenderProbeResult
        switch source {
        case .markup(let markup):
            result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: markup),
                options: options,
                metrics: metrics
            )
        case .document(let document):
            result = FormulaReadOnlyRenderProbe.measure(
                document: document,
                options: options,
                metrics: metrics
            )
        }

        switch result {
        case .success(let measurement):
            let ascent = measurement.baseline
            let descent = max(0, measurement.height - measurement.baseline)
            return .init(
                isSuccess: true,
                summary: String(
                    format: "status=success | width=%.2f | height=%.2f | baseline=%.2f | ascent=%.2f | descent=%.2f | fontRole=standard | fallback=n/a",
                    measurement.width,
                    measurement.height,
                    measurement.baseline,
                    ascent,
                    descent
                )
            )
        case .failure(let reason, let message):
            return .init(
                isSuccess: false,
                summary: "status=failure | reason=\(reason.rawValue) | message=\(message) | fontRole=standard | fallback=n/a"
            )
        }
    }
}

#Preview {
    PlaceholderRenderingComparisonView()
}
