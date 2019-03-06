// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "AddressManager",
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

