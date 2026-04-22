// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TeamTalkKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TeamTalkKit",
            targets: ["TeamTalkKit"])
    ],
    targets: [
        .target(
            name: "TeamTalkC",
            publicHeadersPath: "include"),
        .target(
            name: "TeamTalkKit",
            dependencies: ["TeamTalkC"]),
        .testTarget(
            name: "TeamTalkKitTests",
            dependencies: ["TeamTalkKit", "TeamTalkC"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"], .when(platforms: [.macOS]))
            ])
    ]
)
