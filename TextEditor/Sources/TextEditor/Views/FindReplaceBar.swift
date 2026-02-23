import SwiftUI

struct FindReplaceBar: View {
    @Binding var findText: String
    @Binding var replaceText: String
    @Binding var caseSensitive: Bool
    @Binding var showReplace: Bool

    let matchCount: Int
    let statusMessage: String
    let onReplaceNext: () -> Void
    let onReplaceAll: () -> Void
    let onClose: () -> Void

    @FocusState private var findFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: { showReplace.toggle() }) {
                    Image(systemName: showReplace ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 14)
                }
                .buttonStyle(.plain)
                .help(showReplace ? "Hide Replace" : "Show Replace")

                TextField("Find", text: $findText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140)
                    .focused($findFieldFocused)

                Toggle("Case", isOn: $caseSensitive)
                    .toggleStyle(.checkbox)

                Text("Matches: \(matchCount)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            if showReplace {
                HStack(spacing: 8) {
                    Spacer().frame(width: 14)

                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 140)

                    Button("Replace") {
                        onReplaceNext()
                    }
                    .disabled(findText.isEmpty)

                    Button("Replace All") {
                        onReplaceAll()
                    }
                    .disabled(findText.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            findFieldFocused = true
        }
    }
}
