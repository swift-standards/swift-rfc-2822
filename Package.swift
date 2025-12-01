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
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc2822, targets: [.rfc2822]),
        .library(name: .rfc2822.foundation, targets: [.rfc2822.foundation]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: .rfc2822,
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
            ]
        ),
        .testTarget(
            name: .rfc2822.tests,
            dependencies: [
                .rfc2822
            ]
        ),
        .target(
            name: .rfc2822.foundation,
            dependencies: [
                .rfc2822
            ]
        ),
        .testTarget(
            name: .rfc2822.foundation.tests,
            dependencies: [
                .byName(name: .rfc2822.foundation)
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings =
    existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
}
