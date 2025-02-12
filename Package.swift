// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ai-vapor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftAIVapor",
            targets: ["SwiftAIVapor"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/grepug/swift-ai.git", branch: "main"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.6.1"),
        .package(url: "https://github.com/grepug/concurrency-utils.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SwiftAIVapor",
            dependencies: [
                .product(name: "SwiftAI", package: "swift-ai"),
                .product(name: "SwiftAIServer", package: "swift-ai"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "ConcurrencyUtils", package: "concurrency-utils"),
            ],
            path: "Sources/SwiftAIVapor"
        ),
        .testTarget(
            name: "swift-ai-vaporTests",
            dependencies: ["SwiftAIVapor"]
        ),
    ]
)
