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
        .package(url: "https://github.com/vapor/fluent-sqlite-driver", from: "4.0.0"), //testing only
        .package(url: "https://github.com/binarybirds/spec", from: "1.0.0") // testing only
    ],
    targets: [
        .target(
            name: "SteamPressCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(name: "SteamPressCoreTests", dependencies: [
            .target(name: "SteamPressCore"),
            .product(name: "XCTVapor", package: "vapor"),
            .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            .product(name: "Spec", package: "spec"),
        ])
    ]
)
