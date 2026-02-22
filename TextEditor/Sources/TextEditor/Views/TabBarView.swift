import SwiftUI

struct TabBarView: View {
    @ObservedObject var state: EditorState
    var onClose: (Int) -> Void
    var onSelect: (Int) -> Void
    var onAddTab: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(state.openTabs.indices, id: \.self) { index in
                    TabItem(
                        tab: state.openTabs[index],
                        isActive: state.activeTabIndex == index,
                        onSelect: { onSelect(index) },
                        onClose: { onClose(index) }
                    )
                }

                Button(action: onAddTab) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .help("New Tab")
            }
        }
        .frame(height: 36)
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
    }
}

struct TabItem: View {
    let tab: FileDocument
    let isActive: Bool
    var onSelect: () -> Void
    var onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tab.fileName)
                .font(.system(.caption, design: .monospaced))
            
            if tab.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isActive ? Color.white : Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
        .onTapGesture(perform: onSelect)
    }
}
