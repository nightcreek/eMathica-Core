import SwiftUI

struct FunctionLineArtView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let scaleX = rect.width / 3.2
            let scaleY = rect.height / 2.6

            var axis = Path()
            axis.move(to: CGPoint(x: rect.minX + 20, y: center.y))
            axis.addLine(to: CGPoint(x: rect.maxX - 20, y: center.y))
            axis.move(to: CGPoint(x: center.x, y: rect.minY + 20))
            axis.addLine(to: CGPoint(x: center.x, y: rect.maxY - 20))
            let axisColor = colorScheme == .dark ? Color.white.opacity(0.30) : Color(red: 0.15, green: 0.22, blue: 0.42).opacity(0.22)
            context.stroke(axis, with: .color(axisColor), lineWidth: 1)

            let sinColor = colorScheme == .dark ? Color.white.opacity(0.45) : Color.blue.opacity(0.22)
            let cosColor = colorScheme == .dark ? Color.white.opacity(0.32) : Color.purple.opacity(0.18)
            let parabolaColor = colorScheme == .dark ? Color.white.opacity(0.22) : Color.indigo.opacity(0.14)
            let paramColor = colorScheme == .dark ? Color.white.opacity(0.20) : Color.cyan.opacity(0.14)

            context.stroke(sinPath(center: center, scaleX: scaleX, scaleY: scaleY), with: .color(sinColor), lineWidth: 1)
            context.stroke(cosPath(center: center, scaleX: scaleX, scaleY: scaleY), with: .color(cosColor), lineWidth: 1)
            context.stroke(parabolaPath(center: center, scaleX: scaleX, scaleY: scaleY), with: .color(parabolaColor), lineWidth: 1)
            context.stroke(parametricPath(center: center, scaleX: scaleX, scaleY: scaleY), with: .color(paramColor), lineWidth: 1)

            let text = Text("y = sin x")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
            context.draw(text, at: CGPoint(x: rect.minX + 64, y: rect.minY + 46))

            let text2 = Text("y = cos x")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.26))
            context.draw(text2, at: CGPoint(x: rect.minX + 64, y: rect.minY + 64))
        }
    }

    private func sinPath(center: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> Path {
        var p = Path()
        let steps = 140
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = (-1.6 + 3.2 * t)
            let y = sin(x * 2.0)
            let px = center.x + CGFloat(x) * scaleX * 0.52
            let py = center.y - CGFloat(y) * scaleY * 0.22
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }

    private func cosPath(center: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> Path {
        var p = Path()
        let steps = 140
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = (-1.6 + 3.2 * t)
            let y = cos(x * 2.0)
            let px = center.x + CGFloat(x) * scaleX * 0.52
            let py = center.y - CGFloat(y) * scaleY * 0.22
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }

    private func parabolaPath(center: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> Path {
        var p = Path()
        let steps = 120
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = (-1.3 + 2.6 * t)
            let y = (x - 0.3) * (x - 0.3)
            let px = center.x + CGFloat(x) * scaleX * 0.36
            let py = center.y - CGFloat(y) * scaleY * 0.12
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }

    private func parametricPath(center: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> Path {
        var p = Path()
        let steps = 160
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2.0 * .pi
            let x = sin(t) * 0.9
            let y = sin(2.0 * t) * 0.5
            let px = center.x + CGFloat(x) * scaleX * 0.34
            let py = center.y - CGFloat(y) * scaleY * 0.30
            if i == 0 { p.move(to: CGPoint(x: px, y: py)) } else { p.addLine(to: CGPoint(x: px, y: py)) }
        }
        return p
    }
}

struct GeometryLineArtView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            let a = CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.68)
            let b = CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.60)
            let c = CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.22)
            let o = CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.52)

            var tri = Path()
            tri.move(to: a)
            tri.addLine(to: b)
            tri.addLine(to: c)
            tri.addLine(to: a)
            let primary = colorScheme == .dark ? Color.white.opacity(0.34) : Color(red: 0.16, green: 0.22, blue: 0.42).opacity(0.18)
            let secondary = colorScheme == .dark ? Color.white.opacity(0.14) : Color.purple.opacity(0.10)
            let tertiary = colorScheme == .dark ? Color.white.opacity(0.12) : Color.blue.opacity(0.08)

            context.stroke(tri, with: .color(primary), lineWidth: 1)

            context.stroke(cubeWireframe(in: rect), with: .color(secondary), lineWidth: 1)
            context.stroke(sphereOutline(in: rect), with: .color(tertiary), lineWidth: 1)

            var aux = Path()
            aux.move(to: a)
            aux.addLine(to: o)
            aux.move(to: b)
            aux.addLine(to: o)
            aux.move(to: c)
            aux.addLine(to: o)
            let auxColor = colorScheme == .dark ? Color.white.opacity(0.22) : Color.indigo.opacity(0.10)
            context.stroke(aux, with: .color(auxColor), lineWidth: 1)

            let r = min(rect.width, rect.height) * 0.18
            let circleRect = CGRect(x: o.x - r, y: o.y - r, width: r * 2, height: r * 2)
            let circleColor = colorScheme == .dark ? Color.white.opacity(0.28) : Color.blue.opacity(0.10)
            context.stroke(Path(ellipseIn: circleRect), with: .color(circleColor), lineWidth: 1)

            for (label, pt) in [("A", a), ("B", b), ("C", c), ("O", o)] {
                let dot = colorScheme == .dark ? Color.white.opacity(0.55) : Color.blue.opacity(0.18)
                context.fill(Path(ellipseIn: CGRect(x: pt.x - 2.5, y: pt.y - 2.5, width: 5, height: 5)), with: .color(dot))

                let labelColor = colorScheme == .dark ? Color.white.opacity(0.34) : Color(red: 0.20, green: 0.28, blue: 0.48).opacity(0.20)
                context.draw(Text(label).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(labelColor), at: CGPoint(x: pt.x + 10, y: pt.y - 10))
            }
        }
    }

    private func cubeWireframe(in rect: CGRect) -> Path {
        var p = Path()
        let front = rect.insetBy(dx: rect.width * 0.52, dy: rect.height * 0.58)
        let back = front.offsetBy(dx: rect.width * 0.10, dy: -rect.height * 0.08)

        p.addRect(front)
        p.addRect(back)

        p.move(to: CGPoint(x: front.minX, y: front.minY))
        p.addLine(to: CGPoint(x: back.minX, y: back.minY))
        p.move(to: CGPoint(x: front.maxX, y: front.minY))
        p.addLine(to: CGPoint(x: back.maxX, y: back.minY))
        p.move(to: CGPoint(x: front.minX, y: front.maxY))
        p.addLine(to: CGPoint(x: back.minX, y: back.maxY))
        p.move(to: CGPoint(x: front.maxX, y: front.maxY))
        p.addLine(to: CGPoint(x: back.maxX, y: back.maxY))

        return p
    }

    private func sphereOutline(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.30)
        let r = min(rect.width, rect.height) * 0.16
        let circle = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        p.addEllipse(in: circle)
        p.addEllipse(in: circle.insetBy(dx: r * 0.20, dy: r * 0.52))
        return p
    }
}
