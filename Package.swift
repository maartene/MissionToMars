// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MissionToMars",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "3.3.0")),
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "MailJet", dependencies: ["Vapor"]),
        .target(name: "Model", dependencies: ["Vapor", "FluentSQLite"]),
        .target(name: "App", dependencies: ["Vapor", "Model", "Leaf", "MailJet"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App", "Model", "MailJet"]),
    ]
)

