// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Moltipass",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "Moltipass",
            targets: ["Moltipass", "MoltipassApp"]
        ),
    ],
    targets: [
        // Library code (testable)
        .target(
            name: "Moltipass",
            path: "Sources/Moltipass",
            resources: [
                .process("Resources")
            ]
        ),
        // App entry point (not testable)
        .target(
            name: "MoltipassApp",
            dependencies: ["Moltipass"],
            path: "Sources/MoltipassApp"
        ),
        .testTarget(
            name: "MoltipassTests",
            dependencies: ["Moltipass"],
            path: "Tests/MoltipassTests"
        ),
    ]
)
