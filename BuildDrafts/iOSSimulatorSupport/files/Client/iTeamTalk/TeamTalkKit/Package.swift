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
        .binaryTarget(
            name: "TeamTalkNativeiOS",
            path: "Vendor/TeamTalkNativeiOS.xcframework"),
        .binaryTarget(
            name: "TeamTalkNativemacOS",
            path: "Vendor/TeamTalkNativemacOS.xcframework"),
        .target(
            name: "TeamTalkC",
            dependencies: [
                .target(name: "TeamTalkNativeiOS", condition: .when(platforms: [.iOS])),
                .target(name: "TeamTalkNativemacOS", condition: .when(platforms: [.macOS]))
            ],
            publicHeadersPath: "include"),
        .target(
            name: "TeamTalkKit",
            dependencies: ["TeamTalkC"]),
        .testTarget(
            name: "TeamTalkKitTests",
            dependencies: ["TeamTalkKit", "TeamTalkC"])
    ]
)
