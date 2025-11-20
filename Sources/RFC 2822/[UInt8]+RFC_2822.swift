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

// MARK: - AddrSpec Serialization

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
    /// ## Performance
    ///
    /// Direct byte generation without intermediate String allocations.
    ///
    /// - Parameter addrSpec: The addr-spec to serialize
    public init(_ addrSpec: RFC_2822.AddrSpec) {
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

// MARK: - Mailbox Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Mailbox
    ///
    /// Formats as either "Display Name <addr-spec>" or just "addr-spec".
    ///
    /// - Parameter mailbox: The mailbox to serialize
    public init(_ mailbox: RFC_2822.Mailbox) {
        self = []

        if let displayName = mailbox.displayName {
            // Check if display name needs quoting
            let needsQuoting = displayName.contains(where: { !$0.isASCIILetter && !$0.isASCIIDigit })

            if needsQuoting {
                self.append(UInt8(ascii: "\""))
                self.append(contentsOf: displayName.utf8)
                self.append(UInt8(ascii: "\""))
            } else {
                self.append(contentsOf: displayName.utf8)
            }

            self.append(UInt8.space)
            self.append(UInt8(ascii: "<"))
            self.append(contentsOf: [UInt8](mailbox.emailAddress))
            self.append(UInt8(ascii: ">"))
        } else {
            // Just the addr-spec
            self.append(contentsOf: [UInt8](mailbox.emailAddress))
        }
    }
}

// MARK: - Address Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Address
    ///
    /// - Parameter address: The address to serialize
    public init(_ address: RFC_2822.Address) {
        self = []

        switch address.kind {
        case .mailbox(let mailbox):
            self.append(contentsOf: [UInt8](mailbox))

        case .group(let displayName, let mailboxes):
            // Group format: "Display Name: mailbox1, mailbox2;"
            self.append(contentsOf: displayName.utf8)
            self.append(.colon)

            for (index, mailbox) in mailboxes.enumerated() {
                if index > 0 {
                    self.append(UInt8(ascii: ","))
                    self.append(UInt8.space)
                } else {
                    self.append(UInt8.space)
                }
                self.append(contentsOf: [UInt8](mailbox))
            }

            self.append(UInt8(ascii: ";"))
        }
    }
}

// MARK: - Fields Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Fields
    ///
    /// Serializes all message header fields per RFC 2822 Section 3.6.
    ///
    /// - Parameter fields: The message fields to serialize
    public init(_ fields: RFC_2822.Fields) {
        self = []

        // Helper to add a field line
        func addField(_ name: String, _ value: String) {
            self.append(contentsOf: name.utf8)
            self.append(.colon)
            self.append(.space)
            self.append(contentsOf: value.utf8)
            self.append(.cr)
            self.append(.lf)
        }

        // Add fields in recommended order per RFC 2822

        // Trace fields first
        for received in fields.receivedFields {
            addField("Received", "\(received)")
        }

        if let returnPath = fields.returnPath {
            addField("Return-Path", "\(returnPath)")
        }

        // Resent fields
        for block in fields.resentFields {
            addField("Resent-Date", "\(block.timestamp.secondsSinceEpoch)")
            addField("Resent-From", block.from.map { String(describing: $0) }.joined(separator: ", "))
            if let sender = block.sender {
                addField("Resent-Sender", String(describing: sender))
            }
            if let to = block.to {
                addField("Resent-To", to.map { String(describing: $0) }.joined(separator: ", "))
            }
            if let cc = block.cc {
                addField("Resent-Cc", cc.map { String(describing: $0) }.joined(separator: ", "))
            }
            if let messageID = block.messageID {
                addField("Resent-Message-ID", messageID.description)
            }
        }

        // Required fields
        addField("Date", "\(fields.originationDate.secondsSinceEpoch)")
        addField("From", fields.from.map { String(describing: $0) }.joined(separator: ", "))

        // Optional originator fields
        if let sender = fields.sender {
            addField("Sender", String(describing: sender))
        }
        if let replyTo = fields.replyTo {
            addField("Reply-To", replyTo.map { String(describing: $0) }.joined(separator: ", "))
        }

        // Destination fields
        if let to = fields.to {
            addField("To", to.map { String(describing: $0) }.joined(separator: ", "))
        }
        if let cc = fields.cc {
            addField("Cc", cc.map { String(describing: $0) }.joined(separator: ", "))
        }
        if let bcc = fields.bcc {
            addField("Bcc", bcc.map { String(describing: $0) }.joined(separator: ", "))
        }

        // Identification fields
        if let messageID = fields.messageID {
            addField("Message-ID", messageID.description)
        }
        if let inReplyTo = fields.inReplyTo {
            addField("In-Reply-To", inReplyTo.map(\.description).joined(separator: " "))
        }
        if let references = fields.references {
            addField("References", references.map(\.description).joined(separator: " "))
        }

        // Informational fields
        if let subject = fields.subject {
            addField("Subject", subject)
        }
        if let comments = fields.comments {
            addField("Comments", comments)
        }
        if let keywords = fields.keywords {
            addField("Keywords", keywords.joined(separator: ", "))
        }
    }
}

// MARK: - Message Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Message
    ///
    /// This is the canonical serialization for RFC 2822 messages.
    ///
    /// ## RFC 2822 Message Format
    ///
    /// ```
    /// message = fields CRLF CRLF body
    /// ```
    ///
    /// ## Category Theory
    ///
    /// This is the canonical serialization (natural transformation):
    /// - **Domain**: RFC_2822.Message (structured data)
    /// - **Codomain**: [UInt8] (bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Message → [UInt8] → String (UTF-8 interpretation)
    /// ```
    ///
    /// - Parameter message: The RFC 2822 message to serialize
    public init(_ message: RFC_2822.Message) {
        self = []

        // Serialize fields
        self.append(contentsOf: [UInt8](message.fields))

        // Add body if present
        if let body = message.body {
            // CRLF CRLF separator between headers and body
            self.append(UInt8(ascii: "\r"))
            self.append(UInt8(ascii: "\n"))
            self.append(UInt8(ascii: "\r"))
            self.append(UInt8(ascii: "\n"))

            // Body bytes
            self.append(contentsOf: [UInt8](body))
        }
    }
}

extension [UInt8] {
    /// Creates byte representation of RFC 2822 message body
    ///
    /// This is the identity transformation - the body is already stored as bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the canonical serialization (natural transformation):
    /// ```
    /// Body → [UInt8] (identity)
    /// ```
    ///
    /// - Parameter body: The message body
    public init(_ body: RFC_2822.Message.Body) {
        self = body.bytes
    }
}

// MARK: - Timestamp Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Timestamp
    ///
    /// Serializes as seconds since epoch in decimal ASCII.
    /// Full RFC 2822 date-time formatting would require Date/Calendar APIs.
    ///
    /// - Parameter timestamp: The timestamp to serialize
    public init(_ timestamp: RFC_2822.Timestamp) {
        self = []
        self.append(contentsOf: "\(timestamp.secondsSinceEpoch)".utf8)
    }
}

// MARK: - Message.ID Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Message ID
    ///
    /// Formats as `<idLeft@idRight>` per RFC 2822 Section 3.6.4.
    ///
    /// - Parameter messageID: The message ID to serialize
    public init(_ messageID: RFC_2822.Message.ID) {
        self = []
        self.reserveCapacity(messageID.idLeft.count + messageID.idRight.count + 3)

        self.append(UInt8(ascii: "<"))
        self.append(contentsOf: messageID.idLeft.utf8)
        self.append(UInt8(ascii: "@"))
        self.append(contentsOf: messageID.idRight.utf8)
        self.append(UInt8(ascii: ">"))
    }
}

// MARK: - Message.Path Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Return Path
    ///
    /// Formats as `<addr-spec>` or `<>` if empty.
    ///
    /// - Parameter path: The return path to serialize
    public init(_ path: RFC_2822.Message.Path) {
        self = []

        self.append(UInt8(ascii: "<"))
        if let addrSpec = path.addrSpec {
            self.append(contentsOf: [UInt8](addrSpec))
        }
        self.append(UInt8(ascii: ">"))
    }
}

// MARK: - Message.Received.NameValuePair Serialization

extension [UInt8] {
    /// Creates byte representation of Received field name-value pair
    ///
    /// Formats as "name value".
    ///
    /// - Parameter pair: The name-value pair to serialize
    public init(_ pair: RFC_2822.Message.Received.NameValuePair) {
        self = []
        self.reserveCapacity(pair.name.count + 1 + pair.value.count)

        self.append(contentsOf: pair.name.utf8)
        self.append(UInt8(ascii: " "))
        self.append(contentsOf: pair.value.utf8)
    }
}

// MARK: - Message.Received Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Received field
    ///
    /// Formats as trace tokens followed by semicolon and timestamp.
    ///
    /// - Parameter received: The received field to serialize
    public init(_ received: RFC_2822.Message.Received) {
        self = []

        // Add name-value pairs
        for (index, token) in received.tokens.enumerated() {
            if index > 0 {
                self.append(UInt8(ascii: " "))
            }
            self.append(contentsOf: [UInt8](token))
        }

        // Add semicolon and timestamp
        self.append(UInt8(ascii: ";"))
        self.append(UInt8(ascii: " "))
        self.append(contentsOf: [UInt8](received.timestamp))
    }
}
