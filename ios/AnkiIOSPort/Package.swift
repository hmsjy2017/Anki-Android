// swift-tools-version: 6.0
import Foundation
import PackageDescription

let ankiBackendFFIPath = "../AnkiBackendBridge/build/AnkiBackendFFI.xcframework"
let hasAnkiBackendFFI = FileManager.default.fileExists(atPath: ankiBackendFFIPath)

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
            name: "AnkiIOSPort",
            dependencies: hasAnkiBackendFFI ? ["AnkiBackendFFI"] : []
        ),
        .testTarget(
            name: "AnkiIOSPortTests",
            dependencies: ["AnkiIOSPort"]
        )
    ] + (hasAnkiBackendFFI ? [
        .binaryTarget(
            name: "AnkiBackendFFI",
            path: ankiBackendFFIPath
        )
    ] : [])
)
