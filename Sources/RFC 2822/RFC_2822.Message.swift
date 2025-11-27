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
    /// RFC 2822 compliant message
    ///
    /// Per RFC 2822 Section 3:
    /// ```
    /// message = (fields / obs-fields) [CRLF body]
    /// body = *(*998text CRLF) *998text
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let message = try RFC_2822.Message(ascii: rawMessageBytes)
    /// print(message.fields.subject)
    /// print(message.body)
    /// ```
    public struct Message: Sendable, Codable {
        public let fields: Fields
        public let body: Body?

        /// Creates a message WITHOUT validation
        init(__unchecked: Void, fields: Fields, body: Body?) {
            self.fields = fields
            self.body = body
        }

        /// Canonical initializer
        public init(fields: Fields, body: Body? = nil) {
            self.init(__unchecked: (), fields: fields, body: body)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.Message: Hashable {}

// MARK: - Convenience Initializers

extension RFC_2822.Message {
    /// Convenience initializer with string body
    public init(fields: RFC_2822.Fields, body: String?) {
        self.init(__unchecked: (), fields: fields, body: body.map { Body($0) })
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during message parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case invalidFields(RFC_2822.Fields.Error)

        public var description: String {
            switch self {
            case .empty:
                return "Message cannot be empty"
            case .invalidFields(let error):
                return "Invalid fields: \(error)"
            }
        }
    }

    /// Parses a message from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3
    ///
    /// ```
    /// message = (fields / obs-fields) [CRLF body]
    /// ```
    ///
    /// Headers and body are separated by a blank line (CRLF CRLF).
    ///
    /// - Parameter bytes: The message as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Find the blank line (CRLF CRLF) that separates headers from body
        var headerEndIndex: Int? = nil
        var bodyStartIndex: Int? = nil

        // Look for CRLF CRLF
        for i in 0..<(byteArray.count - 3) {
            if byteArray[i] == .ascii.cr &&
               byteArray[i + 1] == .ascii.lf &&
               byteArray[i + 2] == .ascii.cr &&
               byteArray[i + 3] == .ascii.lf {
                headerEndIndex = i
                bodyStartIndex = i + 4
                break
            }
        }

        // If not found, try LF LF (lenient)
        if headerEndIndex == nil {
            for i in 0..<(byteArray.count - 1) {
                if byteArray[i] == .ascii.lf && byteArray[i + 1] == .ascii.lf {
                    headerEndIndex = i
                    bodyStartIndex = i + 2
                    break
                }
            }
        }

        // Parse fields
        let fieldsBytes: [UInt8]
        let bodyBytes: [UInt8]?

        if let headerEnd = headerEndIndex, let bodyStart = bodyStartIndex {
            fieldsBytes = Array(byteArray[..<headerEnd])
            if bodyStart < byteArray.count {
                bodyBytes = Array(byteArray[bodyStart...])
            } else {
                bodyBytes = nil
            }
        } else {
            // No blank line - treat entire input as headers
            fieldsBytes = byteArray
            bodyBytes = nil
        }

        let fields: RFC_2822.Fields
        do {
            fields = try RFC_2822.Fields(ascii: fieldsBytes)
        } catch {
            throw Error.invalidFields(error)
        }

        let body: Body? = bodyBytes.flatMap { bytes in
            bytes.isEmpty ? nil : Body(bytes)
        }

        self.init(__unchecked: (), fields: fields, body: body)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

// MARK: - Message Nested Types

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

// MARK: - Message.ID Hashable

extension RFC_2822.Message.ID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(idLeft)
        hasher.combine(idRight.lowercased())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.idLeft == rhs.idLeft && lhs.idRight.lowercased() == rhs.idRight.lowercased()
    }
}

// MARK: - Message.ID UInt8.ASCII.Serializable

extension RFC_2822.Message.ID: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during message ID parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case missingAngleBrackets(_ value: String)
        case missingAtSign(_ value: String)
        case invalidIdLeft(_ value: String)
        case invalidIdRight(_ value: String)

        public var description: String {
            switch self {
            case .empty:
                return "Message ID cannot be empty"
            case .missingAngleBrackets(let value):
                return "Message ID must be enclosed in angle brackets: '\(value)'"
            case .missingAtSign(let value):
                return "Message ID must contain '@': '\(value)'"
            case .invalidIdLeft(let value):
                return "Invalid id-left in message ID: '\(value)'"
            case .invalidIdRight(let value):
                return "Invalid id-right in message ID: '\(value)'"
            }
        }
    }

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

// MARK: - Message.ID Protocol Conformances

extension RFC_2822.Message.ID: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.ID: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - Message Other Nested Types

extension RFC_2822.Message {

    /// Return path for trace fields
    public struct Path: Hashable, Sendable, Codable {
        public let addrSpec: RFC_2822.AddrSpec?

        public init(addrSpec: RFC_2822.AddrSpec? = nil) {
            self.addrSpec = addrSpec
        }
    }

    /// Received trace field
    public struct Received: Hashable, Sendable, Codable {
        public struct NameValuePair: Hashable, Sendable, Codable {
            public let name: String
            public let value: String
        }

        public let tokens: [NameValuePair]
        public let timestamp: RFC_2822.Timestamp

        public init(tokens: [NameValuePair], timestamp: RFC_2822.Timestamp) {
            self.tokens = tokens
            self.timestamp = timestamp
        }
    }

    /// Block of resent fields
    public struct ResentBlock: Hashable, Sendable, Codable {
        public let timestamp: RFC_2822.Timestamp
        public let from: [RFC_2822.Mailbox]
        public let sender: RFC_2822.Mailbox?
        public let to: [RFC_2822.Address]?
        public let cc: [RFC_2822.Address]?
        public let bcc: [RFC_2822.Address]?
        public let messageID: ID?

        public init(
            timestamp: RFC_2822.Timestamp,
            from: [RFC_2822.Mailbox],
            sender: RFC_2822.Mailbox? = nil,
            to: [RFC_2822.Address]? = nil,
            cc: [RFC_2822.Address]? = nil,
            bcc: [RFC_2822.Address]? = nil,
            messageID: ID? = nil
        ) {
            self.timestamp = timestamp
            self.from = from
            self.sender = sender
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.messageID = messageID
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.Message: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}
