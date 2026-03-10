# TextEditor — App Summary

A lightweight, native macOS text editor built with **Swift** and **SwiftUI/AppKit**, targeting macOS 12+. Zero external dependencies.

## Features

| Category | Details |
|----------|---------|
| **Multi-tab editing** | Open multiple files in tabs; golden dot indicates unsaved changes |
| **Line numbers** | Synchronized gutter that scrolls with content |
| **Find & Replace** | Case-sensitive search, match counting, replace one/all (`⌘F` / `⌘⌥F`) |
| **Auto-save** | Saves modified files every 10 seconds |
| **Session persistence** | Remembers open files and active tab between launches |
| **File opening** | File dialog, drag-and-drop, CLI arguments, or external apps |
| **Save prompts** | Warns before closing unsaved files |

## Architecture

```
Sources/TextEditor/
├── TextEditorApp.swift            # Entry point & AppDelegate
├── Models/
│   ├── EditorState.swift          # Observable state (tabs, find/replace)
│   └── FileDocument.swift         # File data model (Codable)
├── Views/
│   ├── ContentView.swift          # Root UI, session & file orchestration
│   ├── EditorView.swift           # Editor + find bar + line numbers
│   ├── TabBarView.swift           # Tabs with overflow menu
│   ├── NativeTextEditor.swift     # NSViewRepresentable ↔ NSTextView
│   ├── LineNumberView.swift       # Line number gutter
│   ├── FindReplaceBar.swift       # Find/replace UI
│   └── WindowCloseInterceptor.swift
├── Services/
│   ├── FileService.swift          # File I/O
│   ├── SessionPersistenceService.swift
│   ├── AutoSaveService.swift
│   └── SavePromptService.swift
└── Resources/
    └── app_icon.png
```

**Patterns:** MVVM · Service layer · NSViewRepresentable bridge · Protocol-based DI for testability

## Tech Stack

- **Language:** Swift 5.5+ — **UI:** SwiftUI + AppKit — **Build:** Swift Package Manager
- **~1,700 lines** of source across 15 files; 8 test files with comprehensive coverage
- **Visual style:** Dark background, warm beige accents (`#9B865A`), monospaced font

## Build & Run

```bash
cd TextEditor
swift build            # Build
swift run TextEditor   # Run
swift test             # Test
./package_dmg.sh       # Package as distributable DMG
```

## License

Apache License 2.0
