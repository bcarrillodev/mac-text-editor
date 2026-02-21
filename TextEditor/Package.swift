// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TextEditor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "TextEditor", targets: ["TextEditor"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TextEditor",
            dependencies: [],
            path: "Sources/TextEditor"
        ),
        .testTarget(
            name: "TextEditorTests",
            dependencies: ["TextEditor"],
            path: "Tests/TextEditorTests"
        )
    ]
)
