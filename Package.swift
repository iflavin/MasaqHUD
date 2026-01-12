// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MasaqHUD",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MasaqHUDCore",
            targets: ["MasaqHUDCore"]
        )
    ],
    targets: [
        .target(
            name: "MasaqHUDCore",
            path: "Sources/MasaqHUD",
            exclude: ["main.swift"]
        ),
        .executableTarget(
            name: "MasaqHUD",
            dependencies: ["MasaqHUDCore"],
            path: "Sources/MasaqHUD",
            sources: ["main.swift"]
        ),
        .testTarget(
            name: "MasaqHUDTests",
            dependencies: ["MasaqHUDCore"],
            path: "Tests/MasaqHUDTests"
        )
    ]
)
