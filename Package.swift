// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "MissionToMars",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "4.32.0")),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0-rc"),
        //.package(url: "https://github.com/nodes-vapor/storage.git", from: "1.0.0"),
        .package(name: "AWSSDKSwift", url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0"),
    ],
    targets: [
        //.target(name: "MailJet", dependencies: ["Vapor"]),
        //.target(name: "Model", dependencies: ["Vapor"]),
        .target(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Leaf", package: "leaf"),
            .product(name: "S3", package: "AWSSDKSwift"),
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

