// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWSlider",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "WWSlider", targets: ["WWSlider"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "WWSlider", dependencies: [], resources: [.process("Material"), .process("Xib")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
