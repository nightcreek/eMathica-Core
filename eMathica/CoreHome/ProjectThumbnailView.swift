import SwiftUI
#if canImport(UIKit)
import UIKit
typealias PlatformThumbnailImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformThumbnailImage = NSImage
#endif

struct ProjectThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let kind: ProjectThumbnailKind
    let accent: Color
    let previewURL: URL?

    init(kind: ProjectThumbnailKind, accent: Color, previewURL: URL? = nil) {
        self.kind = kind
        self.accent = accent
        self.previewURL = previewURL
    }

    var body: some View {
        ProjectThumbnailResolvedImageView(
            kind: kind,
            accent: accent,
            previewURL: previewURL,
            colorScheme: colorScheme
        )
    }
}

private struct ProjectThumbnailResolvedImageView: View {
    let kind: ProjectThumbnailKind
    let accent: Color
    let previewURL: URL?
    let colorScheme: ColorScheme

    @State private var resolvedImage: PlatformThumbnailImage?

    var body: some View {
        let cacheIdentity = previewURL.map(ProjectThumbnailImageLoader.cacheIdentity(for:))
        ZStack {
            if let resolvedImage {
                platformImageView(from: resolvedImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(background)

                ThumbnailShape(kind: kind)
                    .stroke(accent.opacity(colorScheme == .dark ? 0.92 : 0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .padding(12)
            }
        }
        .aspectRatio(1.55, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: cacheIdentity) {
            resolvedImage = nil
            guard let previewURL else { return }
            let cacheIdentity = ProjectThumbnailImageLoader.cacheIdentity(for: previewURL)
            if let cached = ProjectThumbnailImageCache.shared.image(for: cacheIdentity) {
                resolvedImage = cached
                return
            }
            let loadedImage = await ProjectThumbnailImageLoader.loadImage(from: previewURL)
            if Task.isCancelled {
                return
            }
            if let loadedImage {
                resolvedImage = loadedImage
            }
        }
    }

    private var background: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [accent.opacity(0.18), Color.black.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color.white, accent.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ProjectThumbnailImageLoader {
    static func cacheIdentity(for url: URL) -> String {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let modificationStamp = (attributes?[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? -1
        let fileSize = (attributes?[.size] as? NSNumber)?.intValue ?? -1
        return "\(url.path)|\(modificationStamp)|\(fileSize)"
    }

    static func loadImage(from url: URL) async -> PlatformThumbnailImage? {
        let cacheIdentity = cacheIdentity(for: url)
        if let cached = ProjectThumbnailImageCache.shared.image(for: cacheIdentity) {
            return cached
        }

        let decodedImage = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: decodeImage(at: url))
            }
        }

        guard let decodedImage else { return nil }
        ProjectThumbnailImageCache.shared.store(decodedImage, for: cacheIdentity)
        return decodedImage
    }

    private static func decodeImage(at url: URL) -> PlatformThumbnailImage? {
        do {
            let data = try Data(contentsOf: url)
#if canImport(UIKit)
            return UIImage(data: data)
#elseif canImport(AppKit)
            return NSImage(data: data)
#else
            return nil
#endif
        } catch {
            return nil
        }
    }
}

final class ProjectThumbnailImageCache {
    static let shared = ProjectThumbnailImageCache()

    private let cache = NSCache<NSString, PlatformThumbnailImageBox>()

    func image(for cacheIdentity: String) -> PlatformThumbnailImage? {
        cache.object(forKey: cacheIdentity as NSString)?.image
    }

    func store(_ image: PlatformThumbnailImage, for cacheIdentity: String) {
        cache.setObject(PlatformThumbnailImageBox(image), forKey: cacheIdentity as NSString)
    }
}

private final class PlatformThumbnailImageBox: NSObject {
    let image: PlatformThumbnailImage

    init(_ image: PlatformThumbnailImage) {
        self.image = image
    }
}

private func platformImageView(from image: PlatformThumbnailImage) -> Image {
#if canImport(UIKit)
    Image(uiImage: image)
#elseif canImport(AppKit)
    Image(nsImage: image)
#endif
}

private struct ThumbnailShape: Shape {
    let kind: ProjectThumbnailKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .parabolaGraph:
            return parabola(in: rect)
        case .circleGeometry:
            return circleGeometry(in: rect)
        case .parametricCurve:
            return parametric(in: rect)
        case .surface3D:
            return surface3D(in: rect)
        case .spiralStairModel:
            return spiral(in: rect)
        case .synthWaveform:
            return waveform(in: rect, cycles: 3)
        case .sequencerBlocks:
            return sequencer(in: rect)
        case .heatmap:
            return heatmap(in: rect)
        case .lineChart:
            return lineChart(in: rect)
        case .formulaNotes:
            return formula(in: rect)
        }
    }

    private func parabola(in rect: CGRect) -> Path {
        var p = axisCross(in: rect)
        let steps = 32
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = -1.2 + 2.4 * t
            let y = x * x
            let px = rect.midX + rect.width * CGFloat(x / 2.4)
            let py = rect.maxY - rect.height * CGFloat((y / 2.0))
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }

    private func circleGeometry(in rect: CGRect) -> Path {
        var p = axisCross(in: rect)
        let r = min(rect.width, rect.height) * 0.28
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        p.move(to: CGPoint(x: c.x - r, y: c.y))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r))
        return p
    }

    private func parametric(in rect: CGRect) -> Path {
        var p = axisCross(in: rect)
        let steps = 60
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let x = sin(t)
            let y = sin(2 * t) * 0.6
            let px = rect.midX + rect.width * 0.38 * CGFloat(x)
            let py = rect.midY - rect.height * 0.30 * CGFloat(y)
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }

    private func surface3D(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let origin = CGPoint(x: rect.minX + w * 0.25, y: rect.maxY - h * 0.20)

        p.move(to: origin)
        p.addLine(to: CGPoint(x: origin.x + w * 0.55, y: origin.y))
        p.move(to: origin)
        p.addLine(to: CGPoint(x: origin.x + w * 0.20, y: origin.y - h * 0.55))
        p.move(to: CGPoint(x: origin.x + w * 0.55, y: origin.y))
        p.addLine(to: CGPoint(x: origin.x + w * 0.75, y: origin.y - h * 0.55))
        p.move(to: CGPoint(x: origin.x + w * 0.20, y: origin.y - h * 0.55))
        p.addLine(to: CGPoint(x: origin.x + w * 0.75, y: origin.y - h * 0.55))

        let gridCount = 5
        for i in 1..<gridCount {
            let t = CGFloat(i) / CGFloat(gridCount)
            p.move(to: CGPoint(x: origin.x + w * 0.55 * t, y: origin.y))
            p.addLine(to: CGPoint(x: origin.x + w * (0.20 + 0.55 * t), y: origin.y - h * 0.55))
        }
        return p
    }

    private func spiral(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let turns = 2.3
        let steps = 90
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let a = t * 2 * .pi * turns
            let r = (min(rect.width, rect.height) * 0.06) + (min(rect.width, rect.height) * 0.30) * CGFloat(t)
            let x = center.x + cos(a) * r
            let y = center.y + sin(a) * r
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }

    private func waveform(in rect: CGRect, cycles: Double) -> Path {
        var p = Path()
        let steps = 60
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = rect.minX + rect.width * CGFloat(t)
            let y = rect.midY + sin(t * cycles * 2 * .pi) * Double(rect.height) * 0.20
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }

    private func sequencer(in rect: CGRect) -> Path {
        var p = Path()
        let rows = 3
        let cols = 6
        let gap = rect.width * 0.03
        let cellW = (rect.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
        let cellH = (rect.height - gap * CGFloat(rows + 1)) / CGFloat(rows)

        for r in 0..<rows {
            for c in 0..<cols {
                if (r + c) % 2 == 0 { continue }
                let x = rect.minX + gap + CGFloat(c) * (cellW + gap)
                let y = rect.minY + gap + CGFloat(r) * (cellH + gap)
                p.addRoundedRect(in: CGRect(x: x, y: y, width: cellW, height: cellH), cornerSize: CGSize(width: 4, height: 4))
            }
        }
        return p
    }

    private func heatmap(in rect: CGRect) -> Path {
        var p = Path()
        let rows = 4
        let cols = 6
        let gap = rect.width * 0.02
        let cellW = (rect.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
        let cellH = (rect.height - gap * CGFloat(rows + 1)) / CGFloat(rows)

        for r in 0..<rows {
            for c in 0..<cols {
                let x = rect.minX + gap + CGFloat(c) * (cellW + gap)
                let y = rect.minY + gap + CGFloat(r) * (cellH + gap)
                p.addRoundedRect(in: CGRect(x: x, y: y, width: cellW, height: cellH), cornerSize: CGSize(width: 3, height: 3))
            }
        }
        return p
    }

    private func lineChart(in rect: CGRect) -> Path {
        var p = axisCross(in: rect)
        let points: [CGPoint] = [
            CGPoint(x: rect.minX + rect.width * 0.10, y: rect.maxY - rect.height * 0.22),
            CGPoint(x: rect.minX + rect.width * 0.26, y: rect.maxY - rect.height * 0.45),
            CGPoint(x: rect.minX + rect.width * 0.44, y: rect.maxY - rect.height * 0.38),
            CGPoint(x: rect.minX + rect.width * 0.64, y: rect.maxY - rect.height * 0.62),
            CGPoint(x: rect.minX + rect.width * 0.86, y: rect.maxY - rect.height * 0.58)
        ]
        if let first = points.first {
            p.move(to: first)
            for pt in points.dropFirst() { p.addLine(to: pt) }
        }
        return p
    }

    private func formula(in rect: CGRect) -> Path {
        var p = Path()
        let left = rect.minX + rect.width * 0.14
        let top = rect.minY + rect.height * 0.22
        let lineGap = rect.height * 0.16

        for i in 0..<4 {
            let y = top + CGFloat(i) * lineGap
            p.move(to: CGPoint(x: left, y: y))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: y))
        }

        p.move(to: CGPoint(x: left, y: rect.midY + rect.height * 0.20))
        p.addLine(to: CGPoint(x: left + rect.width * 0.18, y: rect.midY + rect.height * 0.12))
        p.addLine(to: CGPoint(x: left + rect.width * 0.34, y: rect.midY + rect.height * 0.22))
        return p
    }

    private func axisCross(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.12))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.12))
        return p
    }
}
