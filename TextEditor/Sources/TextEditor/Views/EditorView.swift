import SwiftUI

struct EditorView: View {
    @ObservedObject var state: EditorState
    @State private var editorContent: String = ""
    @State private var lineCount: Int = 1
    
    var body: some View {
        HStack(spacing: 0) {
            if let activeTab = state.getActiveTab() {
                LineNumberView(lineCount: lineCount)
                
                TextEditor(text: $editorContent)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: editorContent) { newValue in
                        state.updateContent(tabIndex: state.activeTabIndex, content: newValue)
                        updateLineCount()
                    }
                    .onAppear {
                        editorContent = activeTab.content
                        updateLineCount()
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
    
    private func updateLineCount() {
        lineCount = editorContent.split(separator: "\n", omittingEmptySubsequences: false).count
    }
}
