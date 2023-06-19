// swift-tools-version:5.7

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
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", exact: "2.6.0") //testing only
    ],
    targets: [
        .target(name: "SteamPressCore", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "fluent"),
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
        ]),
        .testTarget(name: "SteamPressCoreTests", dependencies: ["SteamPressCore"]),
    ]
)
