import SwiftUI
import AppKit

struct TabBarView: View {
    @ObservedObject var state: EditorState
    var onClose: (Int) -> Void
    var onSelect: (Int) -> Void
    var onAddTab: () -> Void
    var onOpenFile: () -> Void
    var onSave: () -> Void
    private let addButtonWidth: CGFloat = 34
    private let overflowButtonWidth: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidths = state.openTabs.map(TabBarViewLayout.estimatedWidth)
            let layout = TabBarViewLayout.computeVisibleAndOverflowIndices(
                availableWidth: max(0, geometry.size.width),
                tabWidths: tabWidths,
                addButtonWidth: addButtonWidth,
                overflowButtonWidth: overflowButtonWidth
            )

            HStack(spacing: 0) {
                ForEach(layout.visibleIndices, id: \.self) { index in
                    TabItem(
                        tab: state.openTabs[index],
                        isActive: state.activeTabIndex == index,
                        onSelect: { onSelect(index) },
                        onClose: { onClose(index) }
                    )
                }

                if !layout.overflowIndices.isEmpty {
                    Menu {
                        ForEach(layout.overflowIndices, id: \.self) { index in
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

                HStack(spacing: 6) {
                    Button("Open") {
                        onOpenFile()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("o", modifiers: .command)
                    .help("Open File")

                    Button("Save") {
                        onSave()
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("s", modifiers: .command)
                    .help("Save")
                }
                .padding(.trailing, 10)
            }
        }
        .frame(height: 24)
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
    }
}

struct TabBarViewLayout {
    static func computeVisibleAndOverflowIndices(
        availableWidth: CGFloat,
        tabWidths: [CGFloat],
        addButtonWidth: CGFloat,
        overflowButtonWidth: CGFloat
    ) -> (visibleIndices: [Int], overflowIndices: [Int]) {
        let allIndices = Array(tabWidths.indices)
        guard !allIndices.isEmpty else { return ([], []) }

        let fullFitCount = fittedPrefixCount(
            availableWidth: max(0, availableWidth - addButtonWidth),
            tabWidths: tabWidths
        )
        if fullFitCount == tabWidths.count {
            return (allIndices, [])
        }

        let overflowFitCount = fittedPrefixCount(
            availableWidth: max(0, availableWidth - addButtonWidth - overflowButtonWidth),
            tabWidths: tabWidths
        )
        return (
            Array(allIndices.prefix(overflowFitCount)),
            Array(allIndices.dropFirst(overflowFitCount))
        )
    }

    static func estimatedWidth(for tab: FileDocument) -> CGFloat {
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize(for: .small), weight: .regular)
        let textWidth = (tab.fileName as NSString).size(withAttributes: [.font: font]).width
        let modifiedDotWidth: CGFloat = tab.isModified ? 12 : 0
        let closeButtonWidth: CGFloat = 14
        let spacingWidth: CGFloat = tab.isModified ? 16 : 10
        let horizontalPadding: CGFloat = 16
        return textWidth + modifiedDotWidth + closeButtonWidth + spacingWidth + horizontalPadding
    }

    private static func fittedPrefixCount(availableWidth: CGFloat, tabWidths: [CGFloat]) -> Int {
        var usedWidth: CGFloat = 0
        var count = 0
        for width in tabWidths {
            if usedWidth + width > availableWidth { break }
            usedWidth += width
            count += 1
        }
        return count
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
