// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// ===----------------------------------------------------------------------===//

// [UInt8]+RFC_2822.swift
// swift-rfc-2822
//
// Canonical byte serialization for RFC 2822 types

import INCITS_4_1986

extension [UInt8] {
    /// Creates ASCII byte representation of RFC 2822 AddrSpec
    ///
    /// This is the canonical serialization to bytes for addr-spec format (local-part@domain).
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_2822.AddrSpec (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// AddrSpec → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Performance
    ///
    /// Direct ASCII generation without intermediate String allocations.
    ///
    /// - Parameter addrSpec: The addr-spec to serialize
    public init(ascii addrSpec: RFC_2822.AddrSpec) {
        self = []
        self.reserveCapacity(addrSpec.localPart.count + 1 + addrSpec.domain.count)

        // local-part
        self.append(contentsOf: addrSpec.localPart.utf8)

        // @
        self.append(UInt8(ascii: "@"))

        // domain
        self.append(contentsOf: addrSpec.domain.utf8)
    }
}
