// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-2822",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(name: "RFC 2822", targets: ["RFC 2822"]),
        .library(name: "RFC 2822 Foundation", targets: ["RFC 2822 Foundation"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-binary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-serializer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-parser.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-incits/swift-incits-4-1986.git", branch: "main"),
        .package(
            url: "https://github.com/swift-molecules/swift-parser.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "RFC 2822",
            dependencies: [
                .product(name: "Binary", package: "swift-binary"),
                .product(
                    name: "ASCII Serializer",
                    package: "swift-ascii-serializer"
                ),
                .product(
                    name: "Parseable ASCII",
                    package: "swift-ascii-parser"
                ),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "Parser", package: "swift-parser"),
            ]
        ),
        .target(
            name: "RFC 2822 Foundation",
            dependencies: [
                .target(name: "RFC 2822")
            ]
        ),
        .testTarget(
            name: "RFC 2822 Foundation Tests",
            dependencies: [
                .target(name: "RFC 2822")
            ]
        ),
        .testTarget(
            name: "RFC 2822 Tests",
            dependencies: [
                .target(name: "RFC 2822")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
