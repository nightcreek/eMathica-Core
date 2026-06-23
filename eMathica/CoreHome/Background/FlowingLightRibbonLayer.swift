import EMathicaThemeKit
import SwiftUI
import Foundation

struct FlowingLightRibbonLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let layout: HomeBackgroundLayout
    let theme: HomeBackgroundTheme
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let indices = visibleRibbonPresetIndices()

                for (displayIndex, presetIndex) in indices.enumerated() {
                    let preset = ribbonPresets[presetIndex]
                    let controls = ribbonControls(
                        preset: preset,
                        time: time,
                        phase: Double(displayIndex) * 0.84,
                        size: size,
                        amplitudeScale: layout.ribbonAmplitudeScale
                    )
                    let path = ribbonPath(from: controls)
                    let sampled = sampleRibbonPoints(
                        start: controls.start,
                        control1: controls.control1,
                        control2: controls.control2,
                        end: controls.end,
                        count: 96
                    )
                    let baseColor = theme.ribbonColors[displayIndex % theme.ribbonColors.count]
                    drawRibbon(
                        path: path,
                        sampledPoints: sampled,
                        color: baseColor,
                        index: displayIndex,
                        time: time,
                        phase: Double(displayIndex) * 0.84,
                        in: &context
                    )
                }
            }
            .blendMode(.screen)
        }
    }

    private func drawRibbon(
        path: Path,
        sampledPoints: [CGPoint],
        color: Color,
        index: Int,
        time: TimeInterval,
        phase: Double,
        in context: inout GraphicsContext
    ) {
        let widthScale = layout.ribbonLineWidthScale
        let blurScale = layout.ribbonBlurScale
        let opacityScale = layout.ribbonOpacityScale

        let isLight = colorScheme != .dark

        // 1) soft body glow: full path
        let outerGlowWidth = max(
            isLight ? 70 : 30,
            (isLight ? 136 : 112) * widthScale - CGFloat(index) * (isLight ? 7.0 : 8.0)
        )
        let outerGlowOpacity = min(
            isLight ? 0.42 : 0.15,
            max(isLight ? 0.24 : 0.07, (isLight ? 0.39 : 0.13) - Double(index) * (isLight ? 0.028 : 0.018))
        )
        let outerGlowBlur = max(
            isLight ? 44 : 50,
            (isLight ? 92 : 72) * blurScale - CGFloat(index) * (isLight ? 4.8 : 3.2)
        )

        context.drawLayer { layer in
            layer.blendMode = .screen
            layer.addFilter(.blur(radius: outerGlowBlur))
            layer.stroke(
                path,
                with: .color(color.opacity(outerGlowOpacity)),
                style: StrokeStyle(lineWidth: outerGlowWidth, lineCap: .round)
            )
        }

        // 2) directional highlight glow: segmented, moving bright peak
        let speed = colorScheme == .dark ? 0.022 : 0.022
        let falloff = colorScheme == .dark ? 0.008 : 0.014
        let highlight = highlightPosition(time: time, phase: phase, speed: speed)
        let directionalColor = directionalHighlightColor(for: index)
        let directionalBaseOpacity: Double = colorScheme == .dark ? 0.30 : 0.40
        let directionalHighlightOpacity: Double = colorScheme == .dark ? 0.58 : 0.72
        let directionalBaseWidth: CGFloat = colorScheme == .dark ? 26 : 44
        let directionalWidthBoost: CGFloat = colorScheme == .dark ? 3.2 : 4.2
        let directionalBlur = max(colorScheme == .dark ? 24 : 24, (colorScheme == .dark ? 38 : 48) * blurScale)

        context.drawLayer { layer in
            layer.blendMode = .screen
            layer.addFilter(.blur(radius: directionalBlur))
            drawDirectionalSegments(
                sampledPoints: sampledPoints,
                highlight: highlight,
                falloff: falloff,
                baseColor: directionalColor,
                baseOpacity: directionalBaseOpacity * opacityScale,
                highlightOpacity: directionalHighlightOpacity * opacityScale,
                baseLineWidth: directionalBaseWidth * widthScale,
                lineWidthBoost: directionalWidthBoost * widthScale,
                in: &layer
            )
        }

        // 3) core highlight line: segmented, brightest near peak
        let coreWidth = max(4.0, (colorScheme == .dark ? 4.6 : 6.8) * widthScale - CGFloat(index) * 0.30)
        let coreOpacity = min(colorScheme == .dark ? 0.95 : 0.90, max(colorScheme == .dark ? 0.75 : 0.65, (colorScheme == .dark ? 0.90 : 0.86) - Double(index) * 0.08))
        let coreBlur = max(colorScheme == .dark ? 2.0 : 2.2, (colorScheme == .dark ? 4.2 : 5.8) * blurScale - CGFloat(index) * 0.35)

        context.drawLayer { layer in
            layer.blendMode = .screen
            layer.addFilter(.blur(radius: coreBlur))
            drawDirectionalSegments(
                sampledPoints: sampledPoints,
                highlight: highlight,
                falloff: colorScheme == .dark ? 0.006 : 0.014,
                baseColor: directionalColor,
                baseOpacity: coreOpacity * (isLight ? 0.28 : 0.22),
                highlightOpacity: coreOpacity,
                baseLineWidth: coreWidth * (isLight ? 0.90 : 0.76),
                lineWidthBoost: colorScheme == .dark ? 2.2 : 3.8,
                in: &layer
            )
        }
    }

    private func drawDirectionalSegments(
        sampledPoints: [CGPoint],
        highlight: CGFloat,
        falloff: CGFloat,
        baseColor: Color,
        baseOpacity: Double,
        highlightOpacity: Double,
        baseLineWidth: CGFloat,
        lineWidthBoost: CGFloat,
        in context: inout GraphicsContext
    ) {
        guard sampledPoints.count >= 2 else { return }
        let segmentCount = sampledPoints.count - 1

        for i in 0..<segmentCount {
            let p0 = sampledPoints[i]
            let p1 = sampledPoints[i + 1]
            let progress = CGFloat(i) / CGFloat(segmentCount)
            let distance = circularDistance(progress, highlight)
            let brightness = exp(-((distance * distance) / max(0.0001, falloff)))
            let opacity = baseOpacity + Double(brightness) * highlightOpacity
            let width = baseLineWidth + brightness * lineWidthBoost

            var segmentPath = Path()
            segmentPath.move(to: p0)
            segmentPath.addLine(to: p1)
            context.stroke(
                segmentPath,
                with: .color(baseColor.opacity(opacity)),
                style: StrokeStyle(lineWidth: width, lineCap: .round)
            )
        }
    }

    private func highlightPosition(time: TimeInterval, phase: Double, speed: Double) -> CGFloat {
        if reduceMotion {
            return CGFloat(fract(0.22 + phase * 0.17))
        }
        return CGFloat(fract(time * speed + phase * 0.13))
    }

    private func circularDistance(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        let raw = abs(a - b)
        return min(raw, 1.0 - raw)
    }

    private func fract(_ value: Double) -> Double {
        value - floor(value)
    }

    private func directionalHighlightColor(for index: Int) -> Color {
        if colorScheme == .dark {
            let darkHighlights: [Color] = [
                Color(red: 0.33, green: 0.93, blue: 1.00), // cyan
                Color(red: 0.42, green: 0.60, blue: 1.00), // blue
                Color(red: 0.74, green: 0.48, blue: 1.00), // violet
                Color(red: 0.96, green: 0.36, blue: 0.84)  // magenta
            ]
            return darkHighlights[index % darkHighlights.count]
        }
        let lightHighlights: [Color] = [
            Color(red: 0.35, green: 0.78, blue: 1.00), // cyan-blue
            Color.white,                                 // white highlight
            Color(red: 0.55, green: 0.68, blue: 1.00), // pale blue
            Color(red: 1.00, green: 0.62, blue: 0.86)  // pink-lavender
        ]
        return lightHighlights[index % lightHighlights.count]
    }

    private func ribbonControls(
        preset: RibbonPreset,
        time: TimeInterval,
        phase: Double,
        size: CGSize,
        amplitudeScale: CGFloat
    ) -> (start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) {
        let drift = CGFloat(sin(time * 0.035 + phase)) * (8 * amplitudeScale)
        let driftY = CGFloat(cos(time * 0.031 + phase * 0.8)) * (7 * amplitudeScale)

        return (
            start: preset.start.resolve(in: size),
            control1: preset.control1.resolve(in: size).applying(CGAffineTransform(translationX: drift, y: driftY)),
            control2: preset.control2.resolve(in: size).applying(CGAffineTransform(translationX: -drift * 0.75, y: -driftY * 0.75)),
            end: preset.end.resolve(in: size)
        )
    }

    private func ribbonPath(from controls: (start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint)) -> Path {
        var path = Path()
        path.move(to: controls.start)
        path.addCurve(to: controls.end, control1: controls.control1, control2: controls.control2)
        return path
    }

    private func sampleRibbonPoints(
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint,
        count: Int
    ) -> [CGPoint] {
        let sampleCount = max(2, count)
        return (0..<sampleCount).map { i in
            let t = CGFloat(i) / CGFloat(sampleCount - 1)
            return cubicBezierPoint(t: t, p0: start, p1: control1, p2: control2, p3: end)
        }
    }

    private func cubicBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let t2 = t * t
        let a = mt2 * mt
        let b = 3 * mt2 * t
        let c = 3 * mt * t2
        let d = t * t2
        return CGPoint(
            x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
            y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
        )
    }

    private func visibleRibbonPresetIndices() -> [Int] {
        switch (colorScheme, layout.profile) {
        case (.dark, .padLandscape):
            return [0, 1, 4, 3] // 3主 + 1辅
        case (.dark, .padPortrait):
            return [0, 1, 4, 3]
        case (.dark, .phonePortrait):
            return [0, 1]
        case (.dark, .phoneLandscape):
            return [0, 1, 4]
        case (.light, .padLandscape):
            return [0, 1, 2, 4]
        case (.light, .padPortrait):
            return [0, 1, 2, 4]
        case (.light, .phonePortrait):
            return [0, 1, 3]
        case (.light, .phoneLandscape):
            return [0, 1, 2]
        @unknown default:
            return Array(0..<min(layout.ribbonCount, ribbonPresets.count))
        }
    }

    private let ribbonPresets: [RibbonPreset] = [
        RibbonPreset(
            start: .normalized(-0.10, 0.78),
            control1: .normalized(0.18, 0.40),
            control2: .normalized(0.58, 0.92),
            end: .normalized(1.10, 0.28)
        ),
        RibbonPreset(
            start: .normalized(-0.08, 0.22),
            control1: .normalized(0.20, 0.06),
            control2: .normalized(0.46, 0.52),
            end: .normalized(1.05, 0.10)
        ),
        RibbonPreset(
            start: .normalized(0.18, -0.10),
            control1: .normalized(0.34, 0.22),
            control2: .normalized(0.70, 0.12),
            end: .normalized(0.98, 0.72)
        ),
        RibbonPreset(
            start: .normalized(-0.12, 0.92),
            control1: .normalized(0.22, 0.74),
            control2: .normalized(0.62, 0.50),
            end: .normalized(1.10, 0.82)
        ),
        RibbonPreset(
            start: .normalized(0.72, -0.08),
            control1: .normalized(0.88, 0.16),
            control2: .normalized(0.78, 0.38),
            end: .normalized(1.08, 0.52)
        )
    ]
}

private struct RibbonPreset {
    let start: RibbonPoint
    let control1: RibbonPoint
    let control2: RibbonPoint
    let end: RibbonPoint
}

private struct RibbonPoint {
    let x: CGFloat
    let y: CGFloat
    let normalized: Bool

    static func normalized(_ x: CGFloat, _ y: CGFloat) -> RibbonPoint {
        RibbonPoint(x: x, y: y, normalized: true)
    }

    func resolve(in size: CGSize) -> CGPoint {
        if normalized {
            return CGPoint(x: x * size.width, y: y * size.height)
        }
        return CGPoint(x: x, y: y)
    }
}
