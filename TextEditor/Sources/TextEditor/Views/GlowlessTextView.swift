import AppKit

class GlowlessTextView: NSTextView {
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        focusRingType = .none
        allowsUndo = true
        isRichText = false
        importsGraphics = false
        drawsBackground = true
    }

    // Draw a solid, glowless insertion point (caret)
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard flag else { return }
        let caretWidth: CGFloat = 1.0
        var caretRect = rect
        caretRect.size.width = caretWidth
        // Center the 1pt caret within provided rect if wider
        caretRect.origin.x = rect.midX - caretWidth / 2.0

        // Ensure no shadow/glow
        NSGraphicsContext.saveGraphicsState()
        NSShadow().set() // Reset any shadow
        color.setFill()
        caretRect.integral.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    // Ensure proper invalidation for blinking without glow
    override func setNeedsDisplay(_ invalidRect: NSRect) {
        // Invalidate a narrow area around the insertion point for crisp redraws
        var rect = invalidRect
        rect.size.width = max(1, rect.size.width)
        super.setNeedsDisplay(rect)
    }
}
