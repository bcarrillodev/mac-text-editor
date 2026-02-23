import SwiftUI
import AppKit

struct LineNumberView: NSViewRepresentable {
    let lineStartOffsets: [CGFloat]
    let scrollOffset: CGFloat
    let lineHeight: CGFloat
    let fontSize: CGFloat
    let topInset: CGFloat

    func makeNSView(context: Context) -> LineNumberGutterNSView {
        let view = LineNumberGutterNSView()
        view.lineStartOffsets = lineStartOffsets
        view.scrollOffset = scrollOffset
        view.lineHeight = lineHeight
        view.fontSize = fontSize
        view.topInset = topInset
        return view
    }

    func updateNSView(_ nsView: LineNumberGutterNSView, context: Context) {
        nsView.lineStartOffsets = lineStartOffsets
        nsView.scrollOffset = scrollOffset
        nsView.lineHeight = lineHeight
        nsView.fontSize = fontSize
        nsView.topInset = topInset
        nsView.needsDisplay = true
    }
}

final class LineNumberGutterNSView: NSView {
    var lineStartOffsets: [CGFloat] = [6]
    var scrollOffset: CGFloat = 0
    var lineHeight: CGFloat = 0
    var fontSize: CGFloat = NSFont.systemFontSize
    var topInset: CGFloat = 6

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        let effectiveLineHeight = max(1, lineHeight)
        let effectiveFont = NSFont.monospacedSystemFont(ofSize: max(1, fontSize), weight: .regular)
        let visibleOffset = max(0, scrollOffset)
        let offsets = lineStartOffsets.isEmpty ? [0] : lineStartOffsets
        let visibleStart = visibleOffset - effectiveLineHeight
        let visibleEnd = visibleOffset + bounds.height + effectiveLineHeight

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.minimumLineHeight = effectiveLineHeight
        paragraphStyle.maximumLineHeight = effectiveLineHeight

        let attributes: [NSAttributedString.Key: Any] = [
            .font: effectiveFont,
            .foregroundColor: NSColor.gray,
            .paragraphStyle: paragraphStyle
        ]

        let startIndex = lowerBound(in: offsets, for: visibleStart)
        if startIndex >= offsets.count {
            return
        }

        for lineIndex in startIndex..<offsets.count {
            let lineOffset = offsets[lineIndex]
            if lineOffset > visibleEnd {
                break
            }

            let baselineOffset: CGFloat = -6
            let y = lineOffset - visibleOffset + topInset + baselineOffset
            let rect = NSRect(x: 0, y: y, width: bounds.width - 8, height: effectiveLineHeight)
            NSString(string: "\(lineIndex + 1)").draw(in: rect, withAttributes: attributes)
        }
    }

    private func lowerBound(in values: [CGFloat], for target: CGFloat) -> Int {
        var low = 0
        var high = values.count

        while low < high {
            let mid = (low + high) / 2
            if values[mid] < target {
                low = mid + 1
            } else {
                high = mid
            }
        }

        return low
    }
}
