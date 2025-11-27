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

extension RFC_2822.Message {
    /// Received trace field
    ///
    /// Per RFC 2822 Section 3.6.7:
    /// ```
    /// received = "Received:" name-val-list ";" date-time CRLF
    /// name-val-list = [CFWS] [name-val-pair *(CFWS name-val-pair)]
    /// name-val-pair = item-name CFWS item-value
    /// ```
    public struct Received: Hashable, Sendable, Codable {
        public struct NameValuePair: Hashable, Sendable, Codable {
            public let name: String
            public let value: String

            public init(name: String, value: String) {
                self.name = name
                self.value = value
            }
        }

        public let tokens: [NameValuePair]
        public let timestamp: RFC_2822.Timestamp

        public init(tokens: [NameValuePair], timestamp: RFC_2822.Timestamp) {
            self.tokens = tokens
            self.timestamp = timestamp
        }
    }
}

// MARK: - NameValuePair [UInt8] Conversion

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
        self.append(.ascii.space)
        self.append(contentsOf: pair.value.utf8)
    }
}

// MARK: - Received [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Received field
    ///
    /// Formats as trace tokens followed by semicolon and timestamp.
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Message.Received → [UInt8]
    ///
    /// - Parameter received: The received field to serialize
    public init(_ received: RFC_2822.Message.Received) {
        self = []

        // Add name-value pairs
        for (index, token) in received.tokens.enumerated() {
            if index > 0 {
                self.append(.ascii.space)
            }
            self.append(contentsOf: [UInt8](token))
        }

        // Add semicolon and timestamp
        self.append(.ascii.semicolon)
        self.append(.ascii.space)
        self.append(contentsOf: [UInt8](received.timestamp))
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.Message.Received: CustomStringConvertible {
    public var description: String {
        String(decoding: [UInt8](self), as: UTF8.self)
    }
}
