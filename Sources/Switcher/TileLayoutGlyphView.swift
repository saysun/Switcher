import AppKit

/// Small pictogram for a window tile region (outline + highlighted segment).
final class TileLayoutGlyphView: NSView {
    enum Kind: Int {
        case leftHalf, rightHalf, topHalf, bottomHalf
        case quarterTopLeft, quarterTopRight, quarterBottomLeft, quarterBottomRight
        case maximize
    }

    var kind: Kind {
        didSet { needsDisplay = true }
    }

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 40, height: 40) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let inset: CGFloat = 4
        let r = bounds.insetBy(dx: inset, dy: inset)
        guard r.width > 2, r.height > 2 else { return }

        let w2 = r.width / 2
        let h2 = r.height / 2
        let fill = NSColor.controlAccentColor.withAlphaComponent(0.4)
        let stroke = NSColor.secondaryLabelColor.withAlphaComponent(0.85)
        let gridLine = NSColor.secondaryLabelColor.withAlphaComponent(0.45)

        func fillRect(_ fr: NSRect) {
            fill.setFill()
            NSBezierPath(rect: fr).fill()
        }

        func strokeRect(_ fr: NSRect) {
            let p = NSBezierPath(rect: fr)
            p.lineWidth = 1
            stroke.setStroke()
            p.stroke()
        }

        switch kind {
        case .leftHalf:
            fillRect(NSRect(x: r.minX, y: r.minY, width: w2, height: r.height))
        case .rightHalf:
            fillRect(NSRect(x: r.midX, y: r.minY, width: w2, height: r.height))
        case .topHalf:
            fillRect(NSRect(x: r.minX, y: r.minY + h2, width: r.width, height: h2))
        case .bottomHalf:
            fillRect(NSRect(x: r.minX, y: r.minY, width: r.width, height: h2))
        case .quarterTopLeft:
            fillRect(NSRect(x: r.minX, y: r.minY + h2, width: w2, height: h2))
        case .quarterTopRight:
            fillRect(NSRect(x: r.midX, y: r.minY + h2, width: w2, height: h2))
        case .quarterBottomLeft:
            fillRect(NSRect(x: r.minX, y: r.minY, width: w2, height: h2))
        case .quarterBottomRight:
            fillRect(NSRect(x: r.midX, y: r.minY, width: w2, height: h2))
        case .maximize:
            NSColor.controlAccentColor.withAlphaComponent(0.22).setFill()
            NSBezierPath(rect: r.insetBy(dx: 1, dy: 1)).fill()
        }

        strokeRect(r)

        gridLine.setStroke()
        let midV = NSBezierPath()
        midV.move(to: NSPoint(x: r.midX, y: r.minY))
        midV.line(to: NSPoint(x: r.midX, y: r.maxY))
        midV.lineWidth = kind == .leftHalf || kind == .rightHalf ? 1 : 0.5

        let midH = NSBezierPath()
        midH.move(to: NSPoint(x: r.minX, y: r.midY))
        midH.line(to: NSPoint(x: r.maxX, y: r.midY))
        midH.lineWidth = kind == .topHalf || kind == .bottomHalf ? 1 : 0.5

        switch kind {
        case .leftHalf, .rightHalf:
            midV.lineWidth = 0.75
            midV.stroke()
        case .topHalf, .bottomHalf:
            midH.lineWidth = 0.75
            midH.stroke()
        case .quarterTopLeft, .quarterTopRight, .quarterBottomLeft, .quarterBottomRight, .maximize:
            midV.lineWidth = 0.5
            midH.lineWidth = 0.5
            midV.stroke()
            midH.stroke()
        }
    }
}
