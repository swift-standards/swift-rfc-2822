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
    /// let addr = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
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
        /// **Warning**: Bypasses RFC 2822 validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        public init(
            __unchecked: Void,
            localPart: String,
            domain: String
        ) {
            self.localPart = localPart
            self.domain = domain
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

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.AddrSpec: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses an addr-spec from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
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
    /// atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" /
    ///         "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" /
    ///         "`" / "{" / "|" / "}" / "~"
    /// ```
    ///
    /// - Parameter bytes: The addr-spec as ASCII bytes
    /// - Throws: `Error` if parsing or validation fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Find the @ separator
        guard let atIndex = byteArray.firstIndex(of: .ascii.commercialAt) else {
            throw Error.missingAtSign(String(decoding: bytes, as: UTF8.self))
        }

        let localPartBytes = Array(byteArray[..<atIndex])
        let domainBytes = Array(byteArray[byteArray.index(after: atIndex)...])

        // ===== VALIDATE LOCAL-PART =====
        // local-part = dot-atom / quoted-string

        guard !localPartBytes.isEmpty else {
            throw Error.invalidLocalPart("")
        }

        let firstLocalByte = localPartBytes[0]
        let lastLocalByte = localPartBytes[localPartBytes.count - 1]

        if firstLocalByte == .ascii.quotationMark && lastLocalByte == .ascii.quotationMark {
            // Quoted-string format
            // quoted-string = DQUOTE *qcontent DQUOTE
            // qcontent = qtext / quoted-pair
            // qtext = NO-WS-CTL / %d33 / %d35-91 / %d93-126
            var isEscaped = false
            for i in 1..<(localPartBytes.count - 1) {
                let byte = localPartBytes[i]
                if isEscaped {
                    isEscaped = false
                } else if byte == UInt8.ascii.reverseSolidus {
                    isEscaped = true
                } else {
                    // qtext validation
                    let isValidQText = (byte >= 1 && byte <= 8) ||
                        byte == 11 || byte == 12 ||
                        (byte >= 14 && byte <= 31) ||
                        byte == 33 ||
                        (byte >= 35 && byte <= 91) ||
                        (byte >= 93 && byte <= 126)
                    guard isValidQText else {
                        throw Error.invalidLocalPart(String(decoding: localPartBytes, as: UTF8.self))
                    }
                }
            }
            if isEscaped {
                throw Error.invalidLocalPart(String(decoding: localPartBytes, as: UTF8.self))
            }
        } else {
            // Dot-atom format
            // dot-atom-text = 1*atext *("." 1*atext)
            // atext = ALPHA / DIGIT / special chars

            // Cannot start or end with dot
            guard firstLocalByte != .ascii.period && lastLocalByte != .ascii.period else {
                throw Error.invalidLocalPart(String(decoding: localPartBytes, as: UTF8.self))
            }

            var previousByte: UInt8 = 0
            for byte in localPartBytes {
                // Check for consecutive dots
                if byte == UInt8.ascii.period && previousByte == .ascii.period {
                    throw Error.invalidLocalPart(String(decoding: localPartBytes, as: UTF8.self))
                }
                previousByte = byte

                // Validate atext or dot
                if byte == UInt8.ascii.period { continue }

                let isAtext = byte.ascii.isLetter || byte.ascii.isDigit ||
                    byte == 0x21 ||                             // ! exclamationMark
                    byte == UInt8.ascii.numberSign ||           // #
                    byte == UInt8.ascii.dollarSign ||           // $
                    byte == UInt8.ascii.percentSign ||          // %
                    byte == UInt8.ascii.ampersand ||            // &
                    byte == UInt8.ascii.apostrophe ||           // '
                    byte == UInt8.ascii.asterisk ||             // *
                    byte == UInt8.ascii.plusSign ||             // +
                    byte == UInt8.ascii.hyphen ||               // -
                    byte == UInt8.ascii.solidus ||              // /
                    byte == UInt8.ascii.equalsSign ||           // =
                    byte == UInt8.ascii.questionMark ||         // ?
                    byte == UInt8.ascii.circumflexAccent ||     // ^
                    byte == 0x5F ||                             // _ lowLine
                    byte == 0x60 ||                             // ` graveAccent
                    byte == 0x7B ||                             // { leftCurlyBracket
                    byte == UInt8.ascii.verticalLine ||         // |
                    byte == 0x7D ||                             // } rightCurlyBracket
                    byte == 0x7E                                // ~ tilde

                guard isAtext else {
                    throw Error.invalidLocalPart(String(decoding: localPartBytes, as: UTF8.self))
                }
            }
        }

        // ===== VALIDATE DOMAIN =====
        // domain = dot-atom / domain-literal

        guard !domainBytes.isEmpty else {
            throw Error.invalidDomain("")
        }

        let firstDomainByte = domainBytes[0]
        let lastDomainByte = domainBytes[domainBytes.count - 1]

        if firstDomainByte == .ascii.leftSquareBracket && lastDomainByte == .ascii.rightSquareBracket {
            // Domain-literal format
            // domain-literal = "[" *dcontent "]"
            // dcontent = dtext / quoted-pair
            // dtext = NO-WS-CTL / %d33-90 / %d94-126
            var isEscaped = false
            for i in 1..<(domainBytes.count - 1) {
                let byte = domainBytes[i]
                if isEscaped {
                    guard byte == UInt8.ascii.leftSquareBracket ||
                          byte == UInt8.ascii.rightSquareBracket ||
                          byte == UInt8.ascii.reverseSolidus else {
                        throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
                    }
                    isEscaped = false
                } else if byte == UInt8.ascii.reverseSolidus {
                    isEscaped = true
                } else {
                    // dtext validation
                    let isValidDText = (byte >= 1 && byte <= 8) ||
                        byte == 11 || byte == 12 ||
                        (byte >= 14 && byte <= 31) ||
                        (byte >= 33 && byte <= 90) ||
                        (byte >= 94 && byte <= 126)
                    guard isValidDText else {
                        throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
                    }
                }
            }
            if isEscaped {
                throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
            }
        } else {
            // Dot-atom format for domain
            // Per RFC 2822, domain dot-atom uses same atext as local-part

            // Cannot start or end with dot
            guard firstDomainByte != .ascii.period && lastDomainByte != .ascii.period else {
                throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
            }

            var previousByte: UInt8 = 0
            for byte in domainBytes {
                // Check for consecutive dots
                if byte == UInt8.ascii.period && previousByte == .ascii.period {
                    throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
                }
                previousByte = byte

                // Validate atext or dot
                if byte == UInt8.ascii.period { continue }

                let isAtext = byte.ascii.isLetter || byte.ascii.isDigit ||
                    byte == 0x21 ||                             // ! exclamationMark
                    byte == UInt8.ascii.numberSign ||           // #
                    byte == UInt8.ascii.dollarSign ||           // $
                    byte == UInt8.ascii.percentSign ||          // %
                    byte == UInt8.ascii.ampersand ||            // &
                    byte == UInt8.ascii.apostrophe ||           // '
                    byte == UInt8.ascii.asterisk ||             // *
                    byte == UInt8.ascii.plusSign ||             // +
                    byte == UInt8.ascii.hyphen ||               // -
                    byte == UInt8.ascii.solidus ||              // /
                    byte == UInt8.ascii.equalsSign ||           // =
                    byte == UInt8.ascii.questionMark ||         // ?
                    byte == UInt8.ascii.circumflexAccent ||     // ^
                    byte == 0x5F ||                             // _ lowLine
                    byte == 0x60 ||                             // ` graveAccent
                    byte == 0x7B ||                             // { leftCurlyBracket
                    byte == UInt8.ascii.verticalLine ||         // |
                    byte == 0x7D ||                             // } rightCurlyBracket
                    byte == 0x7E                                // ~ tilde

                guard isAtext else {
                    throw Error.invalidDomain(String(decoding: domainBytes, as: UTF8.self))
                }
            }
        }

        self.init(
            __unchecked: (),
            localPart: String(decoding: localPartBytes, as: UTF8.self),
            domain: String(decoding: domainBytes, as: UTF8.self)
        )
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.AddrSpec: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.AddrSpec: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 AddrSpec
    ///
    /// This is the canonical serialization to bytes for addr-spec format (local-part@domain).
    ///
    /// ## Category Theory
    ///
    /// This is the universal serialization (natural transformation):
    /// - **Domain**: RFC_2822.AddrSpec (structured data)
    /// - **Codomain**: [UInt8] (bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// AddrSpec → [UInt8] → String (UTF-8 interpretation)
    /// ```
    ///
    /// - Parameter addrSpec: The addr-spec to serialize
    public init(_ addrSpec: RFC_2822.AddrSpec) {
        self = []
        self.reserveCapacity(addrSpec.localPart.count + 1 + addrSpec.domain.count)

        // local-part
        self.append(contentsOf: addrSpec.localPart.utf8)

        // @
        self.append(.ascii.commercialAt)

        // domain
        self.append(contentsOf: addrSpec.domain.utf8)
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 AddrSpec
    ///
    /// - Parameter addrSpec: The addr-spec to convert
    public init(_ addrSpec: RFC_2822.AddrSpec) {
        self = Self(decoding: addrSpec.bytes, as: UTF8.self)
    }
}
