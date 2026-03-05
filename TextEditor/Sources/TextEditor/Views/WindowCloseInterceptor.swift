import SwiftUI
import AppKit

struct WindowCloseInterceptor: NSViewRepresentable {
    let onShouldClose: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onShouldClose: onShouldClose)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onShouldClose = onShouldClose
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(to: nsView.window)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var onShouldClose: () -> Bool
        weak var window: NSWindow?

        init(onShouldClose: @escaping () -> Bool) {
            self.onShouldClose = onShouldClose
        }

        func attachIfNeeded(to window: NSWindow?) {
            guard let window, self.window !== window else { return }
            self.window = window
            window.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            onShouldClose()
        }
    }
}
