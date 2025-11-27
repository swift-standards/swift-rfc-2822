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
    public struct Path: Hashable, Sendable, Codable {
        public let addrSpec: RFC_2822.AddrSpec?

        public init(addrSpec: RFC_2822.AddrSpec? = nil) {
            self.addrSpec = addrSpec
        }
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

// MARK: - CustomStringConvertible

extension RFC_2822.Message.Path: CustomStringConvertible {
    public var description: String {
        String(decoding: [UInt8](self), as: UTF8.self)
    }
}
