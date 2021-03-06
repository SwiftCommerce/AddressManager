// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "AddressManager",
    dependencies: [
        .package(url: "https://github.com/skelpo/JSON.git", .branch("develop")),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL", "JSON"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

