import AppKit

/// FinderWrap's mark: an arrow that wraps around a grid of icons.
///
/// The geometry is defined once, on the same 512×512 artwork grid as the app
/// icon, so the menu bar status item and the panel header both draw the same
/// vector shapes instead of raster or SF Symbol stand-ins.
public enum LogoMark {
    public static let designSize = CGSize(width: 512, height: 512)

    /// Bounding box of the artwork inside the design canvas.
    public static let artBounds = CGRect(x: 79, y: 128, width: 341, height: 262)

    /// Small icons the arrow wraps around (3 on the top row, 2 on the bottom).
    public static let cells: [CGRect] = [
        CGRect(x: 115, y: 128, width: 62, height: 60),
        CGRect(x: 206, y: 128, width: 62, height: 60),
        CGRect(x: 297, y: 128, width: 62, height: 60),
        CGRect(x: 206, y: 328, width: 62, height: 60),
        CGRect(x: 297, y: 328, width: 62, height: 60)
    ]

    public static let cellCornerRadius: CGFloat = 16

    /// Thickness of the arrow stroke, in design-space points.
    public static let strokeWidth: CGFloat = 32

    /// Centre line of the arrow shaft: in from the top right, across, and down.
    public static func shaftPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 397.5, y: 159))
        path.addLine(to: CGPoint(x: 397.5, y: 262.5))
        path.addLine(to: CGPoint(x: 132.5, y: 262.5))
        path.addLine(to: CGPoint(x: 132.5, y: 338))
        return path
    }

    /// Centre line of the arrow head chevron.
    public static func headPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 95, y: 330))
        path.addLine(to: CGPoint(x: 132.5, y: 372))
        path.addLine(to: CGPoint(x: 170, y: 330))
        return path
    }

    public static func cellPath(_ rect: CGRect) -> CGPath {
        CGPath(roundedRect: rect,
               cornerWidth: cellCornerRadius,
               cornerHeight: cellCornerRadius,
               transform: nil)
    }

    /// Aspect ratio of the artwork, used to size the status item image.
    public static var artAspectRatio: CGFloat { artBounds.width / artBounds.height }

    /// Uniform transform that fits the artwork inside `rect`, centred.
    public static func fitTransform(in rect: CGRect) -> CGAffineTransform {
        let scale = min(rect.width / artBounds.width, rect.height / artBounds.height)
        let width = artBounds.width * scale
        let height = artBounds.height * scale
        return CGAffineTransform(translationX: rect.midX - width / 2,
                                 y: rect.midY - height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -artBounds.minX, y: -artBounds.minY)
    }

    /// Template image for the menu bar: the arrow is solid, the wrapped icons
    /// are dimmed so the mark reads at status-item size.
    public static func statusItemImage(height: CGFloat = 17,
                                       accessibilityDescription: String = "FinderWrap") -> NSImage {
        let width = (height * artAspectRatio).rounded()
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let transform = fitTransform(in: rect)
            context.saveGState()
            context.concatenate(transform)
            context.setFillColor(NSColor.black.withAlphaComponent(0.45).cgColor)
            for cell in cells {
                context.addPath(cellPath(cell))
            }
            context.fillPath()
            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(strokeWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(shaftPath())
            context.strokePath()
            context.addPath(headPath())
            context.strokePath()
            context.restoreGState()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }
}
