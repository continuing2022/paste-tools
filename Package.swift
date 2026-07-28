// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PasteTools",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "ClipboardHistory", targets: ["ClipboardHistory"]),
        .executable(name: "PasteTools", targets: ["PasteTools"]),
    ],
    targets: [
        .target(
            name: "ClipboardHistory"
        ),
        .executableTarget(
            name: "PasteTools",
            dependencies: ["ClipboardHistory"],
            linkerSettings: [
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(
            name: "ClipboardHistoryTests",
            dependencies: ["ClipboardHistory"]
        ),
    ]
)
