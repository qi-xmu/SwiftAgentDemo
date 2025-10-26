// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAgentDemo",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/qi-xmu/OpenAI.git", from: "0.4.6"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftAgent",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "Logging", package: "swift-log")
            ]
        )
    ]
)
