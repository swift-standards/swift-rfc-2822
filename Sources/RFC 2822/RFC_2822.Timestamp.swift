// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-2822 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import INCITS_4_1986

extension RFC_2822 {
    /// RFC 2822 timestamp
    ///
    /// Per RFC 2822 Section 3.3:
    /// ```
    /// date-time = [ day-of-week "," ] date FWS time [CFWS]
    /// date = day month year
    /// time = time-of-day FWS zone
    /// ```
    ///
    /// This type stores timestamp as seconds since epoch for simplicity.
    /// Full RFC 2822 date-time formatting requires additional Date/Calendar APIs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let timestamp = RFC_2822.Timestamp(secondsSinceEpoch: 1234567890)
    /// ```
    public struct Timestamp: Sendable, Codable {
        public let secondsSinceEpoch: Double

        /// Creates a timestamp WITHOUT validation
        init(__unchecked: Void, secondsSinceEpoch: Double) {
            self.secondsSinceEpoch = secondsSinceEpoch
        }

        /// Creates a timestamp with the given seconds since epoch
        public init(secondsSinceEpoch: Double) {
            self.init(__unchecked: (), secondsSinceEpoch: secondsSinceEpoch)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.Timestamp: Hashable {}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Timestamp: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during timestamp parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case invalidFormat(_ value: String)

        public var description: String {
            switch self {
            case .empty:
                return "Timestamp cannot be empty"
            case .invalidFormat(let value):
                return "Invalid timestamp format: '\(value)'"
            }
        }
    }

    /// Parses a timestamp from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// This implementation parses a simple numeric seconds-since-epoch format.
    /// Full RFC 2822 date-time parsing would require additional complexity.
    ///
    /// - Parameter bytes: The timestamp as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        var byteArray = Array(bytes)

        // Strip leading/trailing whitespace
        while !byteArray.isEmpty && (byteArray.first == .ascii.space || byteArray.first == .ascii.htab) {
            byteArray.removeFirst()
        }
        while !byteArray.isEmpty && (byteArray.last == .ascii.space || byteArray.last == .ascii.htab) {
            byteArray.removeLast()
        }

        guard !byteArray.isEmpty else { throw Error.empty }

        // Parse as numeric value
        let string = String(decoding: byteArray, as: UTF8.self)
        guard let value = Double(string) else {
            throw Error.invalidFormat(string)
        }

        self.init(__unchecked: (), secondsSinceEpoch: value)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Timestamp: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Timestamp: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Timestamp
    ///
    /// Serializes as seconds since epoch in decimal ASCII.
    /// Full RFC 2822 date-time formatting would require Date/Calendar APIs.
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Timestamp → [UInt8]
    ///
    /// - Parameter timestamp: The timestamp to serialize
    public init(_ timestamp: RFC_2822.Timestamp) {
        self = []
        self.append(contentsOf: "\(timestamp.secondsSinceEpoch)".utf8)
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Timestamp
    ///
    /// - Parameter timestamp: The timestamp to convert
    public init(_ timestamp: RFC_2822.Timestamp) {
        self = Self(decoding: timestamp.bytes, as: UTF8.self)
    }
}
