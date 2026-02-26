// swift-tools-version:6.2

import PackageDescription

extension String {
    static let rfc2822: Self = "RFC 2822"
}

extension Target.Dependency {
    static var rfc2822: Self { .target(name: .rfc2822) }
}

let package = Package(
    name: "swift-rfc-2822",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 2822", targets: ["RFC 2822"]),
        .library(name: "RFC 2822 Foundation", targets: ["RFC 2822 Foundation"])
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-foundations/swift-ascii")
    ],
    targets: [
        .target(
            name: "RFC 2822",
            dependencies: [
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "ASCII", package: "swift-ascii")
            ]
        ),
        .target(
            name: "RFC 2822 Foundation",
            dependencies: [
                .rfc2822
            ]
        ),
        .testTarget(
            name: "RFC 2822 Foundation Tests",
            dependencies: [
                "RFC 2822",
            ]
        ),
        .testTarget(
            name: "RFC 2822 Tests",
            dependencies: [
                "RFC 2822",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
