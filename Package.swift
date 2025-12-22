// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "XFlow", targets: ["XFlow"])
    ],
    dependencies: [
        .package(url: "https://github.com/daneden/Twift.git", branch: "main"),
        .package(path: "LocalDependencies/KeyboardShortcuts"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "XFlow",
            dependencies: [
                .product(name: "Twift", package: "Twift"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftDotenv", package: "swift-dotenv")
            ],
            path: "Sources/XFlow"
        )
    ]
)
