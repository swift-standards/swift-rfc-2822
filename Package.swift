// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc2822: Self = "RFC_2822"
}

extension Target.Dependency {
    static var rfc2822: Self { .target(name: .rfc2822) }
}

let package = Package(
    name: "swift-rfc-2822",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc2822, targets: [.rfc2822]),
    ],
    dependencies: [
        // Add RFC dependencies here as needed
        // .package(url: "https://github.com/swift-web-standards/swift-rfc-1123.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .rfc2822,
            dependencies: [
                // Add target dependencies here
            ]
        ),
        .testTarget(
            name: .rfc2822.tests,
            dependencies: [
                .rfc2822
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }