// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnkiIOSPort",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AnkiIOSPort",
            targets: ["AnkiIOSPort"]
        )
    ],
    targets: [
        .target(
            name: "AnkiIOSPort"
        ),
        .testTarget(
            name: "AnkiIOSPortTests",
            dependencies: ["AnkiIOSPort"]
        )
    ]
)
