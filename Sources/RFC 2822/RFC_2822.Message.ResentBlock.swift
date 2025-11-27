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
    /// Block of resent fields
    ///
    /// Per RFC 2822 Section 3.6.6, resent fields provide trace information
    /// when a message is resent. They appear as a group:
    /// - Resent-Date (required in block)
    /// - Resent-From (required in block)
    /// - Resent-Sender (optional)
    /// - Resent-To (optional)
    /// - Resent-Cc (optional)
    /// - Resent-Bcc (optional)
    /// - Resent-Message-ID (optional)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let block = try RFC_2822.Message.ResentBlock(
    ///     ascii: "Resent-Date: 1234567890\r\nResent-From: user@example.com".utf8
    /// )
    /// ```
    public struct ResentBlock: Hashable, Sendable, Codable {
        public let timestamp: RFC_2822.Timestamp
        public let from: [RFC_2822.Mailbox]
        public let sender: RFC_2822.Mailbox?
        public let to: [RFC_2822.Address]?
        public let cc: [RFC_2822.Address]?
        public let bcc: [RFC_2822.Address]?
        public let messageID: ID?

        /// Creates a resent block WITHOUT validation
        init(
            __unchecked: Void,
            timestamp: RFC_2822.Timestamp,
            from: [RFC_2822.Mailbox],
            sender: RFC_2822.Mailbox?,
            to: [RFC_2822.Address]?,
            cc: [RFC_2822.Address]?,
            bcc: [RFC_2822.Address]?,
            messageID: ID?
        ) {
            self.timestamp = timestamp
            self.from = from
            self.sender = sender
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.messageID = messageID
        }

        /// Creates a resent block with required and optional fields
        public init(
            timestamp: RFC_2822.Timestamp,
            from: [RFC_2822.Mailbox],
            sender: RFC_2822.Mailbox? = nil,
            to: [RFC_2822.Address]? = nil,
            cc: [RFC_2822.Address]? = nil,
            bcc: [RFC_2822.Address]? = nil,
            messageID: ID? = nil
        ) {
            self.init(
                __unchecked: (),
                timestamp: timestamp,
                from: from,
                sender: sender,
                to: to,
                cc: cc,
                bcc: bcc,
                messageID: messageID
            )
        }
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message.ResentBlock: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during resent block parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case missingResentDate(_ value: String)
        case missingResentFrom(_ value: String)
        case invalidTimestamp(_ underlying: RFC_2822.Timestamp.Error)
        case invalidMailbox(_ underlying: RFC_2822.Mailbox.Error)
        case invalidAddress(_ field: String, value: String)
        case invalidMessageID(_ underlying: RFC_2822.Message.ID.Error)

        public var description: String {
            switch self {
            case .empty:
                return "Resent block cannot be empty"
            case .missingResentDate(let value):
                return "Resent block must contain Resent-Date: '\(value)'"
            case .missingResentFrom(let value):
                return "Resent block must contain Resent-From: '\(value)'"
            case .invalidTimestamp(let error):
                return "Invalid timestamp in resent block: \(error)"
            case .invalidMailbox(let error):
                return "Invalid mailbox in resent block: \(error)"
            case .invalidAddress(let field, let value):
                return "Invalid address in \(field): '\(value)'"
            case .invalidMessageID(let error):
                return "Invalid message ID in resent block: \(error)"
            }
        }
    }

    /// Parses a resent block from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.6.6
    ///
    /// Resent fields appear as a block with required Resent-Date and Resent-From.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.Message.ResentBlock (structured data)
    ///
    /// - Parameter bytes: The resent block as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Helper to trim whitespace from byte array
        func trimWhitespace(_ arr: [UInt8]) -> [UInt8] {
            var result = arr
            while !result.isEmpty && (result.first == .ascii.space || result.first == .ascii.htab) {
                result.removeFirst()
            }
            while !result.isEmpty && (result.last == .ascii.space || result.last == .ascii.htab) {
                result.removeLast()
            }
            return result
        }

        // Helper to split bytes on separator
        func splitBytes(_ arr: [UInt8], on separator: UInt8) -> [[UInt8]] {
            var result: [[UInt8]] = []
            var current: [UInt8] = []
            for byte in arr {
                if byte == separator {
                    if !current.isEmpty {
                        result.append(current)
                    }
                    current = []
                } else {
                    current.append(byte)
                }
            }
            if !current.isEmpty {
                result.append(current)
            }
            return result
        }

        // Split into lines (on CR or LF)
        var lines: [[UInt8]] = []
        var currentLine: [UInt8] = []
        for byte in byteArray {
            if byte == .ascii.cr || byte == .ascii.lf {
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = []
                }
            } else {
                currentLine.append(byte)
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        var timestamp: RFC_2822.Timestamp? = nil
        var from: [RFC_2822.Mailbox] = []
        var sender: RFC_2822.Mailbox? = nil
        var to: [RFC_2822.Address]? = nil
        var cc: [RFC_2822.Address]? = nil
        var bcc: [RFC_2822.Address]? = nil
        var messageID: RFC_2822.Message.ID? = nil

        for line in lines {
            // Find colon separator
            guard let colonIndex = line.firstIndex(of: .ascii.colon) else { continue }

            let fieldNameBytes = trimWhitespace(Array(line[..<colonIndex]))
            let fieldValueBytes = trimWhitespace(Array(line[(colonIndex + 1)...]))

            let fieldName = String(decoding: fieldNameBytes, as: UTF8.self).lowercased()

            switch fieldName {
            case "resent-date":
                timestamp = try? RFC_2822.Timestamp(ascii: fieldValueBytes)

            case "resent-from":
                // Parse comma-separated mailboxes
                let mailboxByteArrays = splitBytes(fieldValueBytes, on: .ascii.comma)
                for mailboxBytes in mailboxByteArrays {
                    let trimmed = trimWhitespace(mailboxBytes)
                    guard !trimmed.isEmpty else { continue }
                    if let mailbox = try? RFC_2822.Mailbox(ascii: trimmed) {
                        from.append(mailbox)
                    }
                }

            case "resent-sender":
                sender = try? RFC_2822.Mailbox(ascii: fieldValueBytes)

            case "resent-to":
                var addresses: [RFC_2822.Address] = []
                let addressByteArrays = splitBytes(fieldValueBytes, on: .ascii.comma)
                for addressBytes in addressByteArrays {
                    let trimmed = trimWhitespace(addressBytes)
                    guard !trimmed.isEmpty else { continue }
                    if let address = try? RFC_2822.Address(ascii: trimmed) {
                        addresses.append(address)
                    }
                }
                to = addresses.isEmpty ? nil : addresses

            case "resent-cc":
                var addresses: [RFC_2822.Address] = []
                let addressByteArrays = splitBytes(fieldValueBytes, on: .ascii.comma)
                for addressBytes in addressByteArrays {
                    let trimmed = trimWhitespace(addressBytes)
                    guard !trimmed.isEmpty else { continue }
                    if let address = try? RFC_2822.Address(ascii: trimmed) {
                        addresses.append(address)
                    }
                }
                cc = addresses.isEmpty ? nil : addresses

            case "resent-bcc":
                var addresses: [RFC_2822.Address] = []
                let addressByteArrays = splitBytes(fieldValueBytes, on: .ascii.comma)
                for addressBytes in addressByteArrays {
                    let trimmed = trimWhitespace(addressBytes)
                    guard !trimmed.isEmpty else { continue }
                    if let address = try? RFC_2822.Address(ascii: trimmed) {
                        addresses.append(address)
                    }
                }
                bcc = addresses.isEmpty ? nil : addresses

            case "resent-message-id":
                messageID = try? RFC_2822.Message.ID(ascii: fieldValueBytes)

            default:
                break
            }
        }

        guard let ts = timestamp else {
            throw Error.missingResentDate(String(decoding: byteArray, as: UTF8.self))
        }

        guard !from.isEmpty else {
            throw Error.missingResentFrom(String(decoding: byteArray, as: UTF8.self))
        }

        self.init(
            __unchecked: (),
            timestamp: ts,
            from: from,
            sender: sender,
            to: to,
            cc: cc,
            bcc: bcc,
            messageID: messageID
        )
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.ResentBlock: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Message.ResentBlock: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Resent Block
    ///
    /// Formats as a series of Resent-* header fields.
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Message.ResentBlock → [UInt8]
    ///
    /// - Parameter block: The resent block to serialize
    public init(_ block: RFC_2822.Message.ResentBlock) {
        self = []

        // Helper to add a field line
        func addField(_ name: String, _ value: String) {
            self.append(contentsOf: name.utf8)
            self.append(.ascii.colon)
            self.append(.ascii.space)
            self.append(contentsOf: value.utf8)
            self.append(.ascii.cr)
            self.append(.ascii.lf)
        }

        // Resent-Date (required)
        addField("Resent-Date", "\(block.timestamp.secondsSinceEpoch)")

        // Resent-From (required)
        addField("Resent-From", block.from.map { String(describing: $0) }.joined(separator: ", "))

        // Resent-Sender (optional)
        if let sender = block.sender {
            addField("Resent-Sender", String(describing: sender))
        }

        // Resent-To (optional)
        if let to = block.to {
            addField("Resent-To", to.map { String(describing: $0) }.joined(separator: ", "))
        }

        // Resent-Cc (optional)
        if let cc = block.cc {
            addField("Resent-Cc", cc.map { String(describing: $0) }.joined(separator: ", "))
        }

        // Resent-Bcc (optional)
        if let bcc = block.bcc {
            addField("Resent-Bcc", bcc.map { String(describing: $0) }.joined(separator: ", "))
        }

        // Resent-Message-ID (optional)
        if let messageID = block.messageID {
            addField("Resent-Message-ID", messageID.description)
        }
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Resent Block
    ///
    /// - Parameter block: The resent block to convert
    public init(_ block: RFC_2822.Message.ResentBlock) {
        self = Self(decoding: block.bytes, as: UTF8.self)
    }
}
