// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "steampress-core",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(name: "SteamPressCore", targets: ["SteamPressCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor-community/markdown.git", from: "0.6.1")
    ],
    targets: [
        .target(name: "SteamPressCore", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "fluent"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
            .product(name: "SwiftMarkdown", package: "markdown")
        ]),
        .testTarget(name: "SteamPressCoreTests", dependencies: ["SteamPressCore"]),
    ]
)
