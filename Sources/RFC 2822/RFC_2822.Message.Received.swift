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
    ///
    /// ## Example
    ///
    /// ```swift
    /// let received = try RFC_2822.Message.Received(ascii: "from mail.example.com by mx.example.org; 1234567890".utf8)
    /// ```
    public struct Received: Hashable, Sendable, Codable {
        public let tokens: [NameValuePair]
        public let timestamp: RFC_2822.Timestamp

        /// Creates a received field WITHOUT validation
        init(__unchecked: Void, tokens: [NameValuePair], timestamp: RFC_2822.Timestamp) {
            self.tokens = tokens
            self.timestamp = timestamp
        }

        /// Creates a received field with tokens and timestamp
        public init(tokens: [NameValuePair], timestamp: RFC_2822.Timestamp) {
            self.init(__unchecked: (), tokens: tokens, timestamp: timestamp)
        }
    }
}

// Note: NameValuePair is defined in RFC_2822.Message.Received.NameValuePair.swift

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message.Received: UInt8.ASCII.Serializable {
    static public func serialize<Buffer>(
        ascii received: RFC_2822.Message.Received,
        into buffer: inout Buffer
    ) where Buffer : RangeReplaceableCollection, Buffer.Element == UInt8 {
        
        // Add name-value pairs
        for (index, token) in received.tokens.enumerated() {
            if index > 0 {
                buffer.append(.ascii.space)
            }
            buffer.append(contentsOf: [UInt8](token))
        }

        // Add semicolon and timestamp
        buffer.append(.ascii.semicolon)
        buffer.append(.ascii.space)
        buffer.append(contentsOf: [UInt8](received.timestamp))
    }

    /// Parses a received field from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.6.7
    ///
    /// ```
    /// received = "Received:" name-val-list ";" date-time CRLF
    /// ```
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.Message.Received (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let received = try RFC_2822.Message.Received(ascii: "from mail.example.com; 1234567890".utf8)
    /// ```
    ///
    /// - Parameter bytes: The received field as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Find semicolon that separates name-val-list from timestamp
        guard let semicolonIndex = byteArray.lastIndex(of: .ascii.semicolon) else {
            throw Error.missingSemicolon(String(decoding: bytes, as: UTF8.self))
        }

        // Parse timestamp after semicolon
        let timestampStart = byteArray.index(after: semicolonIndex)
        guard timestampStart < byteArray.endIndex else {
            throw Error.missingTimestamp(String(decoding: bytes, as: UTF8.self))
        }

        var timestampBytes = Array(byteArray[timestampStart...])

        // Strip leading whitespace from timestamp
        while !timestampBytes.isEmpty
            && (timestampBytes.first == .ascii.space || timestampBytes.first == .ascii.htab) {
            timestampBytes.removeFirst()
        }

        guard !timestampBytes.isEmpty else {
            throw Error.missingTimestamp(String(decoding: bytes, as: UTF8.self))
        }

        let timestamp: RFC_2822.Timestamp
        do {
            timestamp = try RFC_2822.Timestamp(ascii: timestampBytes)
        } catch {
            throw Error.invalidTimestamp(error)
        }

        // Parse name-value pairs before semicolon
        let nameValBytes = Array(byteArray[..<semicolonIndex])
        var tokens: [NameValuePair] = []

        // Simple parsing: split on whitespace, pair up name-value
        var currentName: String?
        var currentToken = [UInt8]()

        for byte in nameValBytes {
            if byte == .ascii.space || byte == .ascii.htab {
                if !currentToken.isEmpty {
                    let tokenString = String(decoding: currentToken, as: UTF8.self)
                    if let name = currentName {
                        tokens.append(
                            NameValuePair(__unchecked: (), name: name, value: tokenString)
                        )
                        currentName = nil
                    } else {
                        currentName = tokenString
                    }
                    currentToken = []
                }
            } else {
                currentToken.append(byte)
            }
        }

        // Handle last token
        if !currentToken.isEmpty {
            let tokenString = String(decoding: currentToken, as: UTF8.self)
            if let name = currentName {
                tokens.append(NameValuePair(__unchecked: (), name: name, value: tokenString))
            } else if !tokenString.isEmpty {
                // Unpaired name - use as both name and value
                tokens.append(NameValuePair(__unchecked: (), name: tokenString, value: ""))
            }
        }

        self.init(__unchecked: (), tokens: tokens, timestamp: timestamp)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.Received: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.Received: CustomStringConvertible {}
