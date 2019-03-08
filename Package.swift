// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "AddressManager",
    dependencies: [
        .package(url: "https://github.com/skelpo/JSON.git", from: "0.13.1"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL", "JSONKit"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

