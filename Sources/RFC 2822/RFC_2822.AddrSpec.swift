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
    /// RFC 2822 addr-spec (local-part@domain)
    ///
    /// Per RFC 2822 Section 3.4.1:
    /// ```
    /// addr-spec = local-part "@" domain
    /// local-part = dot-atom / quoted-string
    /// domain = dot-atom / domain-literal
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let addr = try RFC_2822.AddrSpec("user@example.com")
    /// ```
    ///
    /// ## See Also
    ///
    /// - [RFC 2822 Section 3.4.1](https://www.rfc-editor.org/rfc/rfc2822#section-3.4.1)
    public struct AddrSpec: Sendable, Codable {
        public let localPart: String
        public let domain: String

        /// Creates an addr-spec WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(
            __unchecked: Void,
            localPart: String,
            domain: String
        ) {
            self.localPart = localPart
            self.domain = domain
        }

        /// Creates an addr-spec with validation
        ///
        /// - Parameters:
        ///   - localPart: The local part (before @)
        ///   - domain: The domain part (after @)
        /// - Throws: `Error` if validation fails
        public init(
            localPart: String,
            domain: String
        ) throws(Error) {
            // Validate local-part
            guard !localPart.isEmpty else {
                throw Error.invalidLocalPart("")
            }
            try Self.validateLocalPart(localPart.utf8)

            // Validate domain
            guard !domain.isEmpty else {
                throw Error.invalidDomain("")
            }
            try Self.validateDomain(domain.utf8)

            self.init(__unchecked: (), localPart: localPart, domain: domain)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.AddrSpec: Hashable {
    public func hash(into hasher: inout Hasher) {
        // RFC 2822 local-part is case-sensitive, domain is case-insensitive
        hasher.combine(localPart)
        hasher.combine(domain.lowercased())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.localPart == rhs.localPart && lhs.domain.lowercased() == rhs.domain.lowercased()
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2822.AddrSpec: Binary.ASCII.Serializable {

    public static func serialize<Buffer>(
        ascii addrSpec: RFC_2822.AddrSpec,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.reserveCapacity(
            buffer.count + addrSpec.localPart.utf8.count + 1 + addrSpec.domain.utf8.count)

        // local-part
        buffer.append(contentsOf: addrSpec.localPart.utf8)

        // @
        buffer.append(.ascii.commercialAt)

        // domain
        buffer.append(contentsOf: addrSpec.domain.utf8)
    }

    /// Parses an addr-spec from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.AddrSpec (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [UInt8] (UTF-8) → AddrSpec
    /// ```
    ///
    /// ## RFC 2822 Section 3.4.1
    ///
    /// ```
    /// addr-spec = local-part "@" domain
    /// local-part = dot-atom / quoted-string
    /// domain = dot-atom / domain-literal
    /// ```
    ///
    /// - Parameter bytes: The addr-spec as ASCII bytes
    /// - Throws: `Error` if parsing or validation fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        // Find the @ separator (use last @ to handle quoted local-parts with @)
        var atIndex: Bytes.Index?
        for index in bytes.indices {
            if bytes[index] == .ascii.commercialAt {
                atIndex = index
            }
        }

        guard let at = atIndex else {
            throw Error.missingAtSign(String(decoding: bytes, as: UTF8.self))
        }

        // Extract local-part and domain as slices (zero-copy)
        let localPartBytes = bytes[..<at]
        let domainBytes = bytes[bytes.index(after: at)...]

        guard !localPartBytes.isEmpty else {
            throw Error.invalidLocalPart("")
        }

        guard !domainBytes.isEmpty else {
            throw Error.invalidDomain("")
        }

        // Delegate to public validating init
        try self.init(
            localPart: String(decoding: localPartBytes, as: UTF8.self),
            domain: String(decoding: domainBytes, as: UTF8.self)
        )
    }
}

// MARK: - Validation Helpers

extension RFC_2822.AddrSpec {
    /// Validates a local-part per RFC 2822
    ///
    /// local-part = dot-atom / quoted-string
    private static func validateLocalPart<Bytes: Collection>(
        _ bytes: Bytes
    ) throws(Error) where Bytes.Element == UInt8 {
        guard let firstByte = bytes.first else {
            throw Error.invalidLocalPart("")
        }

        // Get last byte by iteration (avoids Array allocation)
        var lastByte = firstByte
        for byte in bytes { lastByte = byte }

        if firstByte == .ascii.quotationMark && lastByte == .ascii.quotationMark {
            // Quoted-string format
            try validateQuotedString(bytes, for: .localPart)
        } else {
            // Dot-atom format
            try validateDotAtom(bytes, for: .localPart)
        }
    }

    /// Validates a domain per RFC 2822
    ///
    /// domain = dot-atom / domain-literal
    private static func validateDomain<Bytes: Collection>(
        _ bytes: Bytes
    ) throws(Error) where Bytes.Element == UInt8 {
        guard let firstByte = bytes.first else {
            throw Error.invalidDomain("")
        }

        // Get last byte by iteration (avoids Array allocation)
        var lastByte = firstByte
        for byte in bytes { lastByte = byte }

        if firstByte == .ascii.leftSquareBracket && lastByte == .ascii.rightSquareBracket {
            // Domain-literal format
            try validateDomainLiteral(bytes)
        } else {
            // Dot-atom format
            try validateDotAtom(bytes, for: .domain)
        }
    }

    /// Part being validated (for error context)
    private enum Part {
        case localPart
        case domain
    }

    /// Validates a dot-atom
    ///
    /// dot-atom-text = 1*atext *("." 1*atext)
    private static func validateDotAtom<Bytes: Collection>(
        _ bytes: Bytes,
        for part: Part
    ) throws(Error) where Bytes.Element == UInt8 {
        guard let firstByte = bytes.first else {
            throw errorFor(part, String(decoding: bytes, as: UTF8.self))
        }

        // Get last byte
        var lastByte = firstByte
        for byte in bytes { lastByte = byte }

        // Cannot start or end with dot
        guard firstByte != .ascii.period && lastByte != .ascii.period else {
            throw errorFor(part, String(decoding: bytes, as: UTF8.self))
        }

        // Validate each byte
        var previousByte: UInt8 = 0
        for byte in bytes {
            // Check for consecutive dots
            if byte == .ascii.period && previousByte == .ascii.period {
                throw errorFor(part, String(decoding: bytes, as: UTF8.self))
            }
            previousByte = byte

            // Period is allowed as separator
            if byte == .ascii.period { continue }

            // Must be atext
            guard RFC_2822.isAtext(byte) else {
                throw errorFor(part, String(decoding: bytes, as: UTF8.self))
            }
        }
    }

    /// Validates a quoted-string
    ///
    /// quoted-string = DQUOTE *qcontent DQUOTE
    /// qcontent = qtext / quoted-pair
    /// qtext = NO-WS-CTL / %d33 / %d35-91 / %d93-126
    private static func validateQuotedString<Bytes: Collection>(
        _ bytes: Bytes,
        for part: Part
    ) throws(Error) where Bytes.Element == UInt8 {
        var isEscaped = false
        var isFirst = true
        var byteCount = 0
        let totalCount = bytes.count

        for byte in bytes {
            byteCount += 1

            // Skip first and last quotes
            if isFirst {
                isFirst = false
                continue
            }
            if byteCount == totalCount { continue }

            if isEscaped {
                isEscaped = false
            } else if byte == .ascii.reverseSolidus {
                isEscaped = true
            } else {
                // qtext validation: NO-WS-CTL / %d33 / %d35-91 / %d93-126
                let isValidQText =
                    (byte >= 1 && byte <= 8) || byte == 11 || byte == 12
                    || (byte >= 14 && byte <= 31) || byte == 33 || (byte >= 35 && byte <= 91)
                    || (byte >= 93 && byte <= 126)
                guard isValidQText else {
                    throw errorFor(part, String(decoding: bytes, as: UTF8.self))
                }
            }
        }

        if isEscaped {
            throw errorFor(part, String(decoding: bytes, as: UTF8.self))
        }
    }

    /// Validates a domain-literal
    ///
    /// domain-literal = "[" *dcontent "]"
    /// dcontent = dtext / quoted-pair
    /// dtext = NO-WS-CTL / %d33-90 / %d94-126
    private static func validateDomainLiteral<Bytes: Collection>(
        _ bytes: Bytes
    ) throws(Error) where Bytes.Element == UInt8 {
        var isEscaped = false
        var isFirst = true
        var byteCount = 0
        let totalCount = bytes.count

        for byte in bytes {
            byteCount += 1

            // Skip first and last brackets
            if isFirst {
                isFirst = false
                continue
            }
            if byteCount == totalCount { continue }

            if isEscaped {
                // Only certain characters can follow backslash
                guard
                    byte == .ascii.leftSquareBracket
                        || byte == .ascii.rightSquareBracket
                        || byte == .ascii.reverseSolidus
                else {
                    throw Error.invalidDomain(String(decoding: bytes, as: UTF8.self))
                }
                isEscaped = false
            } else if byte == .ascii.reverseSolidus {
                isEscaped = true
            } else {
                // dtext validation: NO-WS-CTL / %d33-90 / %d94-126
                let isValidDText =
                    (byte >= 1 && byte <= 8) || byte == 11 || byte == 12
                    || (byte >= 14 && byte <= 31) || (byte >= 33 && byte <= 90)
                    || (byte >= 94 && byte <= 126)
                guard isValidDText else {
                    throw Error.invalidDomain(String(decoding: bytes, as: UTF8.self))
                }
            }
        }

        if isEscaped {
            throw Error.invalidDomain(String(decoding: bytes, as: UTF8.self))
        }
    }

    /// Returns the appropriate error for the part being validated
    private static func errorFor(_ part: Part, _ value: String) -> Error {
        switch part {
        case .localPart: return Error.invalidLocalPart(value)
        case .domain: return Error.invalidDomain(value)
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.AddrSpec: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.AddrSpec: CustomStringConvertible {}
