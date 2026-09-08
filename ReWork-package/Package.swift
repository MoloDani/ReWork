// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ReWork-package",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "ReWork-package",
            targets: ["ReWork-package"]
        ),
    ],
    targets: [
        .target(
            name: "ReWork-package",
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
