import SwiftUI
import AppKit

struct NativeTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var lineStartOffsets: [CGFloat]
    @Binding var scrollOffset: CGFloat
    @Binding var lineHeight: CGFloat
    @Binding var fontSize: CGFloat
    @Binding var topInset: CGFloat
    @Binding var cursorPosition: Int
    var findText: String = ""
    var caseSensitive: Bool = false
    var requestFocus: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            lineStartOffsets: $lineStartOffsets,
            scrollOffset: $scrollOffset,
            lineHeight: $lineHeight,
            fontSize: $fontSize,
            topInset: $topInset,
            cursorPosition: $cursorPosition
        )
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        if let editorFont = textView.font {
            textView.typingAttributes[.font] = editorFont
        }
        textView.backgroundColor = .textBackgroundColor
        textView.delegate = context.coordinator
        textView.string = text
        textView.textContainerInset = NSSize(width: 4, height: 6)
        context.coordinator.textView = textView
        context.coordinator.bindScrollObservation(to: scrollView)
        context.coordinator.updateMetrics(from: textView)

        DispatchQueue.main.async {
            if requestFocus {
                textView.window?.makeFirstResponder(textView)
            }
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = (nsView.documentView as? NSTextView) ?? context.coordinator.textView else { return }
        context.coordinator.textView = textView
        context.coordinator.updateMetrics(from: textView)

        if textView.string != text {
            textView.string = text
            if let editorFont = textView.font {
                textView.typingAttributes[.font] = editorFont
            }
            let maxLocation = (text as NSString).length
            let clampedLocation = min(cursorPosition, maxLocation)
            let updatedSelection = NSRange(location: clampedLocation, length: 0)
            textView.setSelectedRange(updatedSelection)
            textView.scrollRangeToVisible(updatedSelection)
        }

        applyHighlights(to: textView)

        if requestFocus && textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    private func applyHighlights(to textView: NSTextView) {
        guard let layoutManager = textView.layoutManager else { return }
        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)

        guard !findText.isEmpty else { return }

        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        let nsString = textView.string as NSString
        var searchRange = NSRange(location: 0, length: nsString.length)

        while searchRange.length > 0 {
            let matchRange = nsString.range(of: findText, options: options, range: searchRange)
            guard matchRange.location != NSNotFound else { break }
            layoutManager.addTemporaryAttribute(
                .backgroundColor,
                value: NSColor.systemBlue.withAlphaComponent(0.6),
                forCharacterRange: matchRange
            )
            let nextLocation = matchRange.location + matchRange.length
            searchRange = NSRange(location: nextLocation, length: nsString.length - nextLocation)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        @Binding var lineStartOffsets: [CGFloat]
        @Binding var scrollOffset: CGFloat
        @Binding var lineHeight: CGFloat
        @Binding var fontSize: CGFloat
        @Binding var topInset: CGFloat
        @Binding var cursorPosition: Int
        weak var textView: NSTextView?
        weak var observedScrollView: NSScrollView?
        private var lastObservedContentWidth: CGFloat = 0

        init(
            text: Binding<String>,
            lineStartOffsets: Binding<[CGFloat]>,
            scrollOffset: Binding<CGFloat>,
            lineHeight: Binding<CGFloat>,
            fontSize: Binding<CGFloat>,
            topInset: Binding<CGFloat>,
            cursorPosition: Binding<Int>
        ) {
            _text = text
            _lineStartOffsets = lineStartOffsets
            _scrollOffset = scrollOffset
            _lineHeight = lineHeight
            _fontSize = fontSize
            _topInset = topInset
            _cursorPosition = cursorPosition
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            text = textView.string
            cursorPosition = textView.selectedRange().location
            updateLineStartOffsets(from: textView)
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard replacementString == "\n" else { return true }

            let currentText = textView.string as NSString
            let cursorLocation = textView.selectedRange().location
            let textLength = currentText.length
            let lineStarts = Self.logicalLineStartIndices(in: currentText)
            let lastLineStart = lineStarts.last ?? 0

            var currentLineStart = 0
            var currentLineEnd = 0
            var currentLineContentsEnd = 0
            currentText.getLineStart(
                &currentLineStart,
                end: &currentLineEnd,
                contentsEnd: &currentLineContentsEnd,
                for: NSRange(location: min(cursorLocation, max(0, textLength)), length: 0)
            )

            if currentLineStart >= lastLineStart {
                return true
            }

            let currentColumn = max(0, cursorLocation - currentLineStart)

            var nextLineStart = 0
            var nextLineEnd = 0
            var nextLineContentsEnd = 0
            currentText.getLineStart(
                &nextLineStart,
                end: &nextLineEnd,
                contentsEnd: &nextLineContentsEnd,
                for: NSRange(location: currentLineEnd, length: 0)
            )

            let nextLineLength = max(0, nextLineContentsEnd - nextLineStart)
            let targetLocation = nextLineStart + min(currentColumn, nextLineLength)
            let newSelection = NSRange(location: targetLocation, length: 0)
            textView.setSelectedRange(newSelection)
            textView.scrollRangeToVisible(newSelection)

            DispatchQueue.main.async {
                self.cursorPosition = targetLocation
            }

            return false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView else { return }
            let location = textView.selectedRange().location
            DispatchQueue.main.async {
                self.cursorPosition = location
            }
        }

        func bindScrollObservation(to scrollView: NSScrollView) {
            guard observedScrollView !== scrollView else { return }
            if let existing = observedScrollView {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSView.boundsDidChangeNotification,
                    object: existing.contentView
                )
            }

            observedScrollView = scrollView
            scrollView.contentView.postsBoundsChangedNotifications = true
            lastObservedContentWidth = scrollView.contentView.bounds.width
            DispatchQueue.main.async {
                self.scrollOffset = scrollView.contentView.bounds.origin.y
            }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClipViewBoundsChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }

        func updateMetrics(from textView: NSTextView) {
            guard let layoutManager = textView.layoutManager else { return }
            let font = textView.font ?? .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            let newLineHeight = layoutManager.defaultLineHeight(for: font)
            let newFontSize = font.pointSize
            let newTopInset = textView.textContainerInset.height

            DispatchQueue.main.async {
                self.lineHeight = newLineHeight
                self.fontSize = newFontSize
                self.topInset = newTopInset
                self.updateLineStartOffsets(from: textView)
            }
        }

        private func updateLineStartOffsets(from textView: NSTextView) {
            guard
                let layoutManager = textView.layoutManager,
                let textContainer = textView.textContainer
            else {
                return
            }

            layoutManager.ensureLayout(for: textContainer)

            let textOriginY = textView.textContainerOrigin.y
            let currentText = textView.string as NSString
            let textLength = currentText.length
            let startIndices = Self.logicalLineStartIndices(in: currentText)
            var offsets: [CGFloat] = []
            offsets.reserveCapacity(startIndices.count)

            for startIndex in startIndices {
                let y: CGFloat
                if startIndex < textLength {
                    let glyphIndex = layoutManager.glyphIndexForCharacter(at: startIndex)
                    let rect = layoutManager.lineFragmentRect(
                        forGlyphAt: glyphIndex,
                        effectiveRange: nil,
                        withoutAdditionalLayout: false
                    )
                    y = textOriginY + rect.minY
                } else {
                    let extraLineRect = layoutManager.extraLineFragmentRect
                    if !extraLineRect.isEmpty {
                        y = textOriginY + extraLineRect.minY
                    } else if let previous = offsets.last {
                        y = previous + max(1, lineHeight)
                    } else {
                        y = textOriginY
                    }
                }
                offsets.append(y)
            }

            if offsets.isEmpty {
                offsets = [textOriginY]
            }

            if Self.hasMeaningfulDifference(lhs: offsets, rhs: lineStartOffsets) {
                lineStartOffsets = offsets
            }
        }

        private static func logicalLineStartIndices(in string: NSString) -> [Int] {
            let length = string.length
            guard length > 0 else {
                return [0]
            }

            var starts = [0]
            var searchLocation = 0

            while searchLocation < length {
                let searchRange = NSRange(location: searchLocation, length: length - searchLocation)
                let newlineRange = string.range(of: "\n", options: [], range: searchRange)
                if newlineRange.location == NSNotFound {
                    break
                }

                let nextLocation = newlineRange.location + newlineRange.length
                starts.append(nextLocation)
                searchLocation = nextLocation
            }

            return starts
        }

        private static func hasMeaningfulDifference(lhs: [CGFloat], rhs: [CGFloat]) -> Bool {
            guard lhs.count == rhs.count else {
                return true
            }

            for index in lhs.indices where abs(lhs[index] - rhs[index]) > 0.25 {
                return true
            }

            return false
        }

        @objc private func handleClipViewBoundsChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView else { return }
            scrollOffset = clipView.bounds.origin.y

            let width = clipView.bounds.width
            if abs(width - lastObservedContentWidth) > 0.25 {
                lastObservedContentWidth = width
                if let textView {
                    updateLineStartOffsets(from: textView)
                }
            }
        }

        deinit {
            if let observedScrollView {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSView.boundsDidChangeNotification,
                    object: observedScrollView.contentView
                )
            }
        }
    }
}
