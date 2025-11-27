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

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message.Path: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

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

extension RFC_2822.Message.Path: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.Path: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Return Path
    ///
    /// Formats as `<addr-spec>` or `<>` if empty.
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Message.Path → [UInt8]
    ///
    /// - Parameter path: The return path to serialize
    public init(_ path: RFC_2822.Message.Path) {
        self = []

        self.append(.ascii.lessThanSign)
        if let addrSpec = path.addrSpec {
            self.append(contentsOf: [UInt8](addrSpec))
        }
        self.append(.ascii.greaterThanSign)
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Return Path
    ///
    /// - Parameter path: The path to convert
    public init(_ path: RFC_2822.Message.Path) {
        self = Self(decoding: path.bytes, as: UTF8.self)
    }
}
