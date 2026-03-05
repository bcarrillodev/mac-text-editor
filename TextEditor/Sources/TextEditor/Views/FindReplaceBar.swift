import SwiftUI

struct FindReplaceBar: View {
    private static let focusColor = Color(red: 0.608, green: 0.525, blue: 0.353) // #9B865A

    private enum Field: Hashable {
        case find
        case replace
    }

    @Binding var findText: String
    @Binding var replaceText: String
    @Binding var caseSensitive: Bool
    @Binding var showReplace: Bool

    let matchCount: Int
    let statusMessage: String
    let onReplaceNext: () -> Void
    let onReplaceAll: () -> Void
    let onClose: () -> Void

    @FocusState private var focusedField: Field?

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

                findReplaceField("Find", text: $findText, field: .find)

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

                    findReplaceField("Replace", text: $replaceText, field: .replace)

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
            focusedField = .find
        }
    }

    private func findReplaceField(_ title: String, text: Binding<String>, field: Field) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        focusedField == field ? Self.focusColor : Color(NSColor.separatorColor),
                        lineWidth: focusedField == field ? 2 : 1
                    )
            )
            .focused($focusedField, equals: field)
            .accentColor(Self.focusColor)
    }
}
