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
    /// Return path for trace fields
    ///
    /// Per RFC 2822 Section 3.6.7:
    /// ```
    /// return = "Return-Path:" path CRLF
    /// path = ([CFWS] "<" ([CFWS] / addr-spec) ">" [CFWS]) / obs-path
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let path = try RFC_2822.Message.Path(ascii: "<user@example.com>".utf8)
    /// let emptyPath = try RFC_2822.Message.Path(ascii: "<>".utf8)
    /// ```
    public struct Path: Hashable, Sendable, Codable {
        public let addrSpec: RFC_2822.AddrSpec?

        /// Creates a path WITHOUT validation
        init(__unchecked: Void, addrSpec: RFC_2822.AddrSpec?) {
            self.addrSpec = addrSpec
        }

        /// Creates a path with optional address specification
        public init(addrSpec: RFC_2822.AddrSpec? = nil) {
            self.init(__unchecked: (), addrSpec: addrSpec)
        }
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2822.Message.Path: Binary.ASCII.Serializable {
    static public func serialize<Buffer>(
        ascii path: RFC_2822.Message.Path,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.append(.ascii.lessThanSign)
        if let addrSpec = path.addrSpec {
            buffer.append(contentsOf: [UInt8](addrSpec))
        }
        buffer.append(.ascii.greaterThanSign)
    }

    /// Parses a return path from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.6.7
    ///
    /// ```
    /// path = ([CFWS] "<" ([CFWS] / addr-spec) ">" [CFWS]) / obs-path
    /// ```
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.Message.Path (structured data)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let path = try RFC_2822.Message.Path(ascii: "<user@example.com>".utf8)
    /// ```
    ///
    /// - Parameter bytes: The path as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        var byteArray = Array(bytes)

        // Strip leading/trailing whitespace (CFWS)
        while !byteArray.isEmpty
            && (byteArray.first == .ascii.space || byteArray.first == .ascii.htab) {
            byteArray.removeFirst()
        }
        while !byteArray.isEmpty
            && (byteArray.last == .ascii.space || byteArray.last == .ascii.htab) {
            byteArray.removeLast()
        }

        guard !byteArray.isEmpty else { throw Error.empty }

        // Must be enclosed in angle brackets
        guard byteArray.first == .ascii.lessThanSign && byteArray.last == .ascii.greaterThanSign
        else {
            throw Error.missingAngleBrackets(String(decoding: bytes, as: UTF8.self))
        }

        // Extract content between < and >
        let contentBytes = Array(byteArray[1..<(byteArray.count - 1)])

        // Empty path <> is valid
        if contentBytes.isEmpty {
            self.init(__unchecked: (), addrSpec: nil)
            return
        }

        // Parse addr-spec
        let addrSpec: RFC_2822.AddrSpec
        do {
            addrSpec = try RFC_2822.AddrSpec(ascii: contentBytes)
        } catch {
            throw Error.invalidAddrSpec(error)
        }

        self.init(__unchecked: (), addrSpec: addrSpec)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.Path: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.Path: CustomStringConvertible {}
