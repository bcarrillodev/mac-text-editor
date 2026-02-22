import SwiftUI

struct TabBarView: View {
    @ObservedObject var state: EditorState
    var onClose: (Int) -> Void
    var onSelect: (Int) -> Void
    var onAddTab: () -> Void
    private let estimatedTabWidth: CGFloat = 150
    private let addButtonWidth: CGFloat = 34
    private let overflowButtonWidth: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            let visibleCount = maxVisibleTabCount(for: geometry.size.width)
            let visibleIndices = Array(state.openTabs.indices.prefix(visibleCount))
            let overflowIndices = Array(state.openTabs.indices.dropFirst(visibleCount))

            HStack(spacing: 0) {
                ForEach(visibleIndices, id: \.self) { index in
                    TabItem(
                        tab: state.openTabs[index],
                        isActive: state.activeTabIndex == index,
                        onSelect: { onSelect(index) },
                        onClose: { onClose(index) }
                    )
                }

                if !overflowIndices.isEmpty {
                    Menu {
                        ForEach(overflowIndices, id: \.self) { index in
                            Button {
                                onSelect(index)
                            } label: {
                                if state.activeTabIndex == index {
                                    Label(state.openTabs[index].fileName, systemImage: "checkmark")
                                } else {
                                    Text(state.openTabs[index].fileName)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: overflowButtonWidth)
                    .help("More Tabs")
                }

                Button(action: onAddTab) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .frame(width: addButtonWidth)
                .help("New Tab")

                Spacer(minLength: 0)
            }
        }
        .frame(height: 36)
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
    }

    private func maxVisibleTabCount(for width: CGFloat) -> Int {
        let reservedWidth = addButtonWidth + overflowButtonWidth
        let availableWidth = max(0, width - reservedWidth)
        return Int(availableWidth / estimatedTabWidth)
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
