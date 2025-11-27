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

extension RFC_2822.Message.Received {
    /// Name-value pair in a Received trace field
    ///
    /// Per RFC 2822 Section 3.6.7:
    /// ```
    /// name-val-pair = item-name CFWS item-value
    /// item-name = ALPHA *(["-"] (ALPHA / DIGIT))
    /// item-value = 1*angle-addr / addr-spec / atom / domain / msg-id
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let pair = try RFC_2822.Message.Received.NameValuePair(ascii: "from mail.example.com".utf8)
    /// print(pair.name)  // "from"
    /// print(pair.value) // "mail.example.com"
    /// ```
    public struct NameValuePair: Hashable, Sendable, Codable {
        public let name: String
        public let value: String

        /// Creates a name-value pair WITHOUT validation
        init(__unchecked: Void, name: String, value: String) {
            self.name = name
            self.value = value
        }

        /// Creates a name-value pair with name and value
        public init(name: String, value: String) {
            self.init(__unchecked: (), name: name, value: value)
        }
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message.Received.NameValuePair: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses a name-value pair from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.6.7
    ///
    /// ```
    /// name-val-pair = item-name CFWS item-value
    /// ```
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.Message.Received.NameValuePair (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let pair = try RFC_2822.Message.Received.NameValuePair(ascii: "from mail.example.com".utf8)
    /// ```
    ///
    /// - Parameter bytes: The name-value pair as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        var byteArray = Array(bytes)

        // Strip leading/trailing whitespace
        while !byteArray.isEmpty
            && (byteArray.first == .ascii.space || byteArray.first == .ascii.htab) {
            byteArray.removeFirst()
        }
        while !byteArray.isEmpty
            && (byteArray.last == .ascii.space || byteArray.last == .ascii.htab) {
            byteArray.removeLast()
        }

        guard !byteArray.isEmpty else { throw Error.empty }

        // Find first whitespace that separates name from value
        var nameEndIndex: Int?
        for (index, byte) in byteArray.enumerated() {
            if byte == .ascii.space || byte == .ascii.htab {
                nameEndIndex = index
                break
            }
        }

        let name: String
        let value: String

        if let endIndex = nameEndIndex {
            name = String(decoding: byteArray[..<endIndex], as: UTF8.self)

            // Extract value after whitespace
            var valueStart = endIndex
            while valueStart < byteArray.count
                && (byteArray[valueStart] == .ascii.space || byteArray[valueStart] == .ascii.htab) {
                valueStart += 1
            }

            if valueStart < byteArray.count {
                value = String(decoding: byteArray[valueStart...], as: UTF8.self)
            } else {
                value = ""
            }
        } else {
            // No whitespace - entire input is the name
            name = String(decoding: byteArray, as: UTF8.self)
            value = ""
        }

        guard !name.isEmpty else { throw Error.empty }

        self.init(__unchecked: (), name: name, value: value)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.Received.NameValuePair: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.Received.NameValuePair: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of Received field name-value pair
    ///
    /// Formats as "name value".
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Message.Received.NameValuePair → [UInt8]
    ///
    /// - Parameter pair: The name-value pair to serialize
    public init(_ pair: RFC_2822.Message.Received.NameValuePair) {
        self = []
        self.reserveCapacity(pair.name.count + 1 + pair.value.count)

        self.append(contentsOf: pair.name.utf8)
        if !pair.value.isEmpty {
            self.append(.ascii.space)
            self.append(contentsOf: pair.value.utf8)
        }
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Received name-value pair
    ///
    /// - Parameter pair: The name-value pair to convert
    public init(_ pair: RFC_2822.Message.Received.NameValuePair) {
        self = Self(decoding: pair.bytes, as: UTF8.self)
    }
}
