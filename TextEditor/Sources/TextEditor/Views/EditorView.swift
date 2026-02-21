import SwiftUI

struct EditorView: View {
    @ObservedObject var state: EditorState
    @State private var editorContent: String = ""
    @State private var lineCount: Int = 1

    var body: some View {
        HStack(spacing: 0) {
            if state.getActiveTab() != nil {
                LineNumberView(lineCount: lineCount)

                TextEditor(text: $editorContent)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: editorContent) { newValue in
                        state.updateContent(tabIndex: state.activeTabIndex, content: newValue)
                        updateLineCount()
                    }
                    .onAppear {
                        loadActiveTabContent()
                    }
                    .onChange(of: state.activeTabIndex) { _ in
                        loadActiveTabContent()
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
    }

    private func loadActiveTabContent() {
        if let tab = state.getActiveTab() {
            editorContent = tab.content
            updateLineCount(for: tab.content)
        }
    }

    private func updateLineCount(for content: String? = nil) {
        let source = content ?? editorContent
        let newlineCount = source.utf8.reduce(into: 0) { count, byte in
            if byte == 10 {
                count += 1
            }
        }
        lineCount = max(1, newlineCount + 1)
    }
}
