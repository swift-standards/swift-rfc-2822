//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

extension RFC_2822 {
    /// RFC 2822 timestamp (seconds since epoch)
    public struct Timestamp: Hashable, Sendable, Codable {
        public let secondsSinceEpoch: Double

        public init(secondsSinceEpoch: Double) {
            self.secondsSinceEpoch = secondsSinceEpoch
        }
    }
}
