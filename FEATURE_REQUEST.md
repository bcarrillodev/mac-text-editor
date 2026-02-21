# macOS Text Editor - Core Features

## Requirement Summary
Create a native macOS text editor application with tabs, auto-save/caching, and line numbers.

## Features
1. **Tab support** - Edit multiple files simultaneously
2. **Auto-save/cache** - Persist editor state (file contents, open tabs, cursor position) for session recovery
3. **Line numbers** - Display line numbers in left margin
4. **No syntax highlighting** - Plain text only

## User Expectation
Similar to Notepad++ for Windows - user can close app or shutdown machine, reopen app, and resume editing exactly where they left off.

## Technical Scope
- macOS-native (SwiftUI recommended)
- File I/O operations
- Session state persistence (UserDefaults or file-based cache)
- Tab management UI
- Line numbering renderer
