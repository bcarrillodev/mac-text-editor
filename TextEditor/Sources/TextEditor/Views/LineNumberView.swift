import SwiftUI

struct LineNumberView: View {
    let lineCount: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...max(1, lineCount), id: \.self) { lineNumber in
                Text("\(lineNumber)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
            }
        }
        .frame(width: 50, alignment: .topTrailing)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
