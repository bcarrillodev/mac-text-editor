import Foundation

class SessionPersistenceService {
    static let shared = SessionPersistenceService()
    private let sessionKey = "EditorSession"
    
    struct SessionData: Codable {
        var openTabs: [FileDocument]
        var activeTabIndex: Int
        var fileContents: [String: String]
        var cursorPositions: [String: Int]
    }
    
    func saveSession(state: EditorState) throws {
        var fileContents: [String: String] = [:]
        var cursorPositions: [String: Int] = [:]
        
        for tab in state.openTabs {
            fileContents[tab.filePath] = tab.content
            cursorPositions[tab.filePath] = tab.cursorPosition
        }
        
        let sessionData = SessionData(
            openTabs: state.openTabs,
            activeTabIndex: state.activeTabIndex,
            fileContents: fileContents,
            cursorPositions: cursorPositions
        )
        
        let encoded = try JSONEncoder().encode(sessionData)
        UserDefaults.standard.set(encoded, forKey: sessionKey)
    }
    
    func loadSession() -> EditorState? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else {
            return nil
        }
        
        do {
            let sessionData = try JSONDecoder().decode(SessionData.self, from: data)
            let state = EditorState()
            state.openTabs = sessionData.openTabs
            state.activeTabIndex = sessionData.activeTabIndex
            
            // Restore content and cursor positions
            for i in 0..<state.openTabs.count {
                if let content = sessionData.fileContents[state.openTabs[i].filePath] {
                    state.openTabs[i].content = content
                }
                if let cursor = sessionData.cursorPositions[state.openTabs[i].filePath] {
                    state.openTabs[i].cursorPosition = cursor
                }
            }
            
            return state
        } catch {
            return nil
        }
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
}
