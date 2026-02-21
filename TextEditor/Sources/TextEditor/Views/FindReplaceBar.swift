import SwiftUI

struct FindReplaceBar: View {
    @Binding var findText: String
    @Binding var replaceText: String
    @Binding var caseSensitive: Bool

    let matchCount: Int
    let statusMessage: String
    let onReplaceNext: () -> Void
    let onReplaceAll: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Find", text: $findText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 140)

            TextField("Replace", text: $replaceText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 140)

            Toggle("Case", isOn: $caseSensitive)
                .toggleStyle(.checkbox)

            Button("Replace") {
                onReplaceNext()
            }
            .disabled(findText.isEmpty)

            Button("Replace All") {
                onReplaceAll()
            }
            .disabled(findText.isEmpty)

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
        .background(Color(NSColor.controlBackgroundColor))
    }
}
