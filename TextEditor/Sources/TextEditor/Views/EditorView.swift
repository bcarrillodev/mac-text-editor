import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var state: EditorState
    @State private var editorContent: String = ""
    @State private var editorLineStartOffsets: [CGFloat] = [6]
    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var caseSensitive: Bool = false
    @State private var matchCount: Int = 0
    @State private var statusMessage: String = ""
    @State private var shouldFocusEditor: Bool = false
    @State private var showFindReplaceBar: Bool = false
    @State private var showReplace: Bool = false
    @State private var keyMonitor: Any?
    @State private var editorScrollOffset: CGFloat = 0
    @State private var editorLineHeight: CGFloat = 0
    @State private var editorFontSize: CGFloat = NSFont.systemFontSize
    @State private var editorTopInset: CGFloat = 6
    @State private var editorCursorPosition: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if state.getActiveTab() != nil {
                if showFindReplaceBar {
                    FindReplaceBar(
                        findText: $findText,
                        replaceText: $replaceText,
                        caseSensitive: $caseSensitive,
                        showReplace: $showReplace,
                        matchCount: matchCount,
                        statusMessage: statusMessage,
                        onReplaceNext: replaceNext,
                        onReplaceAll: replaceAll,
                        onClose: closeFindReplaceBar
                    )
                }

                HStack(alignment: .top, spacing: 0) {
                    LineNumberView(
                        lineStartOffsets: editorLineStartOffsets,
                        scrollOffset: editorScrollOffset,
                        lineHeight: editorLineHeight,
                        fontSize: editorFontSize,
                        topInset: editorTopInset
                    )
                    .frame(width: 50)

                    NativeTextEditor(
                        text: $editorContent,
                        lineStartOffsets: $editorLineStartOffsets,
                        scrollOffset: $editorScrollOffset,
                        lineHeight: $editorLineHeight,
                        fontSize: $editorFontSize,
                        topInset: $editorTopInset,
                        cursorPosition: $editorCursorPosition,
                        findText: showFindReplaceBar ? findText : "",
                        caseSensitive: caseSensitive,
                        requestFocus: shouldFocusEditor
                    )
                        .onChange(of: editorContent) { newValue in
                            state.updateContent(tabIndex: state.activeTabIndex, content: newValue)
                            state.updateCursorPosition(tabIndex: state.activeTabIndex, position: editorCursorPosition)
                            refreshMatchCount()
                        }
                        .onChange(of: editorCursorPosition) { newPosition in
                            state.updateCursorPosition(tabIndex: state.activeTabIndex, position: newPosition)
                        }
                        .onAppear {
                            loadActiveTabContent()
                            focusEditor()
                            installKeyboardMonitor()
                        }
                        .onDisappear {
                            removeKeyboardMonitor()
                        }
                        .onChange(of: state.activeTabIndex) { _ in
                            loadActiveTabContent()
                            focusEditor()
                        }
                }
            } else {
                VStack {
                    Text("No file open")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onChange(of: findText) { _ in
            refreshMatchCount()
        }
        .onChange(of: caseSensitive) { _ in
            refreshMatchCount()
        }
    }

    private func focusEditor() {
        DispatchQueue.main.async {
            shouldFocusEditor = false
            shouldFocusEditor = true
        }
    }

    private func installKeyboardMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let key = event.charactersIgnoringModifiers?.lowercased()

            if modifiers == [.command, .option], key == "f" {
                showFindReplaceBar = true
                showReplace = true
                shouldFocusEditor = false
                refreshMatchCount()
                return nil
            }

            if modifiers == .command, key == "f" {
                showFindReplaceBar = true
                showReplace = false
                shouldFocusEditor = false
                refreshMatchCount()
                return nil
            }

            if event.keyCode == 53, showFindReplaceBar {
                closeFindReplaceBar()
                return nil
            }

            return event
        }
    }

    private func removeKeyboardMonitor() {
        guard let keyMonitor else { return }
        NSEvent.removeMonitor(keyMonitor)
        self.keyMonitor = nil
    }

    private func closeFindReplaceBar() {
        showFindReplaceBar = false
        showReplace = false
        focusEditor()
    }

    private func loadActiveTabContent() {
        if let tab = state.getActiveTab() {
            editorContent = tab.content
            editorCursorPosition = tab.cursorPosition
            refreshMatchCount()
            statusMessage = ""
        }
    }

    private func refreshMatchCount() {
        matchCount = state.findMatchCount(inActiveTab: findText, caseSensitive: caseSensitive)
    }

    private func replaceNext() {
        let replaced = state.replaceNextInActiveTab(find: findText, with: replaceText, caseSensitive: caseSensitive)
        if replaced {
            loadActiveTabContent()
            statusMessage = "Replaced 1"
        } else {
            statusMessage = "No matches"
        }
    }

    private func replaceAll() {
        let replacedCount = state.replaceAllInActiveTab(find: findText, with: replaceText, caseSensitive: caseSensitive)
        loadActiveTabContent()
        if replacedCount > 0 {
            statusMessage = "Replaced \(replacedCount)"
        } else {
            statusMessage = "No matches"
        }
    }
}
