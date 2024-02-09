// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MissionToMars",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.5.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.1.0"),
        //.package(url: "https://github.com/nodes-vapor/storage.git", from: "1.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.1.0")
    ],
    targets: [
        //.target(name: "MailJet", dependencies: ["Vapor"]),
        //.target(name: "Model", dependencies: ["Vapor"]),
        .target(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Leaf", package: "leaf"),
            .product(name: "SotoS3", package: "soto"),
        ]),
        .executableTarget(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
