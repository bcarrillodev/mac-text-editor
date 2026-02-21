import Foundation
import OSLog

class SessionPersistenceService {
    static let shared = SessionPersistenceService()
    private let sessionKey: String
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "mac-text-editor", category: "SessionPersistenceService")

    init(
        sessionKey: String = "EditorSession",
        userDefaults: UserDefaults = .standard
    ) {
        self.sessionKey = sessionKey
        self.userDefaults = userDefaults
    }

    struct SessionData: Codable {
        var openTabs: [FileDocument]
        var activeTabIndex: Int
    }

    func saveSession(state: EditorState) throws {
        let sessionData = SessionData(
            openTabs: state.openTabs,
            activeTabIndex: state.activeTabIndex
        )

        let encoded = try JSONEncoder().encode(sessionData)
        userDefaults.set(encoded, forKey: sessionKey)
    }

    func loadSession() -> EditorState? {
        guard let data = userDefaults.data(forKey: sessionKey) else {
            return nil
        }
        
        do {
            let sessionData = try JSONDecoder().decode(SessionData.self, from: data)
            let state = EditorState()
            state.openTabs = sessionData.openTabs
            state.activeTabIndex = sessionData.activeTabIndex
            return state
        } catch {
            logger.error("Failed to decode saved session: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
    }
}
