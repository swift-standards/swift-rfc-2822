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
    /// Message identifier as defined in RFC 2822 Section 3.6.4
    ///
    /// Per RFC 2822:
    /// ```
    /// msg-id = [CFWS] "<" id-left "@" id-right ">" [CFWS]
    /// id-left = dot-atom-text / no-fold-quote
    /// id-right = dot-atom-text / no-fold-literal
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let id = try RFC_2822.Message.ID(ascii: "<unique-id@example.com>".utf8)
    /// print(id.idLeft)  // "unique-id"
    /// print(id.idRight) // "example.com"
    /// ```
    public struct ID: Sendable, Codable {
        public let idLeft: String
        public let idRight: String

        /// Creates a message ID WITHOUT validation
        init(__unchecked: Void, idLeft: String, idRight: String) {
            self.idLeft = idLeft
            self.idRight = idRight
        }

        /// Creates a validated message ID
        public init(idLeft: String, idRight: String) {
            self.init(__unchecked: (), idLeft: idLeft, idRight: idRight)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.Message.ID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(idLeft)
        hasher.combine(idRight.lowercased())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.idLeft == rhs.idLeft && lhs.idRight.lowercased() == rhs.idRight.lowercased()
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message.ID: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Parses a message ID from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.6.4
    ///
    /// ```
    /// msg-id = [CFWS] "<" id-left "@" id-right ">" [CFWS]
    /// id-left = dot-atom-text / no-fold-quote
    /// id-right = dot-atom-text / no-fold-literal
    /// ```
    ///
    /// - Parameter bytes: The message ID as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        var byteArray = Array(bytes)

        // Strip leading/trailing whitespace (CFWS)
        while !byteArray.isEmpty && (byteArray.first == .ascii.space || byteArray.first == .ascii.htab) {
            byteArray.removeFirst()
        }
        while !byteArray.isEmpty && (byteArray.last == .ascii.space || byteArray.last == .ascii.htab) {
            byteArray.removeLast()
        }

        guard !byteArray.isEmpty else { throw Error.empty }

        // Must be enclosed in angle brackets
        guard byteArray.first == .ascii.lessThanSign && byteArray.last == .ascii.greaterThanSign else {
            throw Error.missingAngleBrackets(String(decoding: bytes, as: UTF8.self))
        }

        // Extract content between < and >
        let contentBytes = Array(byteArray[1..<(byteArray.count - 1)])

        // Find @ separator
        guard let atIndex = contentBytes.firstIndex(of: .ascii.commercialAt) else {
            throw Error.missingAtSign(String(decoding: bytes, as: UTF8.self))
        }

        let idLeftBytes = Array(contentBytes[..<atIndex])
        let idRightBytes = Array(contentBytes[(atIndex + 1)...])

        // ===== VALIDATE ID-LEFT =====
        // id-left = dot-atom-text / no-fold-quote

        guard !idLeftBytes.isEmpty else {
            throw Error.invalidIdLeft("")
        }

        let firstLeftByte = idLeftBytes[0]
        let lastLeftByte = idLeftBytes[idLeftBytes.count - 1]

        if firstLeftByte == .ascii.quotationMark && lastLeftByte == .ascii.quotationMark {
            // no-fold-quote: DQUOTE *(qtext / quoted-pair) DQUOTE
            var isEscaped = false
            for i in 1..<(idLeftBytes.count - 1) {
                let byte = idLeftBytes[i]
                if isEscaped {
                    isEscaped = false
                } else if byte == UInt8.ascii.reverseSolidus {
                    isEscaped = true
                } else {
                    // qtext: printable ASCII except \ and "
                    let isValidQText = (byte >= 32 && byte <= 126) &&
                        byte != .ascii.reverseSolidus &&
                        byte != .ascii.quotationMark
                    guard isValidQText else {
                        throw Error.invalidIdLeft(String(decoding: idLeftBytes, as: UTF8.self))
                    }
                }
            }
            if isEscaped {
                throw Error.invalidIdLeft(String(decoding: idLeftBytes, as: UTF8.self))
            }
        } else {
            // dot-atom-text: 1*atext *("." 1*atext)
            guard firstLeftByte != .ascii.period && lastLeftByte != .ascii.period else {
                throw Error.invalidIdLeft(String(decoding: idLeftBytes, as: UTF8.self))
            }

            var previousByte: UInt8 = 0
            for byte in idLeftBytes {
                if byte == UInt8.ascii.period && previousByte == .ascii.period {
                    throw Error.invalidIdLeft(String(decoding: idLeftBytes, as: UTF8.self))
                }
                previousByte = byte

                if byte == UInt8.ascii.period { continue }

                // atext per RFC 2822
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
                    throw Error.invalidIdLeft(String(decoding: idLeftBytes, as: UTF8.self))
                }
            }
        }

        // ===== VALIDATE ID-RIGHT =====
        // id-right = dot-atom-text / no-fold-literal

        guard !idRightBytes.isEmpty else {
            throw Error.invalidIdRight("")
        }

        let firstRightByte = idRightBytes[0]
        let lastRightByte = idRightBytes[idRightBytes.count - 1]

        if firstRightByte == .ascii.leftSquareBracket && lastRightByte == .ascii.rightSquareBracket {
            // no-fold-literal: "[" *dtext "]"
            for i in 1..<(idRightBytes.count - 1) {
                let byte = idRightBytes[i]
                // dtext: printable ASCII except [ ] \
                let isValidDText = (byte >= 33 && byte <= 90) || (byte >= 94 && byte <= 126)
                guard isValidDText else {
                    throw Error.invalidIdRight(String(decoding: idRightBytes, as: UTF8.self))
                }
            }
        } else {
            // dot-atom-text
            guard firstRightByte != .ascii.period && lastRightByte != .ascii.period else {
                throw Error.invalidIdRight(String(decoding: idRightBytes, as: UTF8.self))
            }

            var previousByte: UInt8 = 0
            for byte in idRightBytes {
                if byte == UInt8.ascii.period && previousByte == .ascii.period {
                    throw Error.invalidIdRight(String(decoding: idRightBytes, as: UTF8.self))
                }
                previousByte = byte

                if byte == UInt8.ascii.period { continue }

                // atext per RFC 2822
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
                    throw Error.invalidIdRight(String(decoding: idRightBytes, as: UTF8.self))
                }
            }
        }

        self.init(
            __unchecked: (),
            idLeft: String(decoding: idLeftBytes, as: UTF8.self),
            idRight: String(decoding: idRightBytes, as: UTF8.self)
        )
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.ID: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.ID: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Message ID
    ///
    /// Formats as `<idLeft@idRight>` per RFC 2822 Section 3.6.4.
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Message.ID → [UInt8]
    ///
    /// - Parameter messageID: The message ID to serialize
    public init(_ messageID: RFC_2822.Message.ID) {
        self = []
        self.reserveCapacity(messageID.idLeft.count + messageID.idRight.count + 3)

        self.append(.ascii.lessThanSign)
        self.append(contentsOf: messageID.idLeft.utf8)
        self.append(.ascii.commercialAt)
        self.append(contentsOf: messageID.idRight.utf8)
        self.append(.ascii.greaterThanSign)
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Message ID
    ///
    /// - Parameter messageID: The message ID to convert
    public init(_ messageID: RFC_2822.Message.ID) {
        self = Self(decoding: messageID.bytes, as: UTF8.self)
    }
}
