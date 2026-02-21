import SwiftUI

struct ContentView: View {
    @StateObject private var state = EditorState()
    @StateObject private var autoSaveService = AutoSaveService()
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(
                state: state,
                onClose: closeTab,
                onSelect: selectTab
            )
            
            EditorView(state: state)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            loadSession()
            startAutoSave()
        }
        .onDisappear {
            saveSession()
            autoSaveService.stopAutoSave()
        }
    }
    
    private func closeTab(_ index: Int) {
        state.closeTab(at: index)
    }
    
    private func selectTab(_ index: Int) {
        state.switchToTab(index: index)
    }
    
    private func loadSession() {
        if let savedState = SessionPersistenceService.shared.loadSession() {
            state.openTabs = savedState.openTabs
            state.activeTabIndex = savedState.activeTabIndex
        }
    }
    
    private func saveSession() {
        try? SessionPersistenceService.shared.saveSession(state: state)
    }
    
    private func startAutoSave() {
        autoSaveService.startAutoSave { [weak state] in
            guard let state = state else { return }
            for tab in state.openTabs {
                if tab.isModified {
                    try? FileService.shared.writeFile(path: tab.filePath, content: tab.content)
                }
            }
            state.markAllSaved()
            try? SessionPersistenceService.shared.saveSession(state: state)
        }
    }
}
