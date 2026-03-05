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

        // Ensure no shadow/glow
        NSGraphicsContext.saveGraphicsState()
        NSShadow().set() // Reset any shadow
        color.setFill()
        rect.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}
