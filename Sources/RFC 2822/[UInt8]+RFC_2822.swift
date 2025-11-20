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

            self.append(UInt8(ascii: " "))
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
            self.append(UInt8(ascii: ":"))

            for (index, mailbox) in mailboxes.enumerated() {
                if index > 0 {
                    self.append(UInt8(ascii: ","))
                    self.append(UInt8(ascii: " "))
                } else {
                    self.append(UInt8(ascii: " "))
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
    public init(rfc2822Fields fields: RFC_2822.Fields) {
        self = []

        // Helper to add a field line
        func addField(_ name: String, _ value: String) {
            self.append(contentsOf: name.utf8)
            self.append(UInt8(ascii: ":"))
            self.append(UInt8(ascii: " "))
            self.append(contentsOf: value.utf8)
            self.append(UInt8(ascii: "\r"))
            self.append(UInt8(ascii: "\n"))
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
    public init(rfc2822Message message: RFC_2822.Message) {
        self = []

        // Serialize fields
        self.append(contentsOf: [UInt8](rfc2822Fields: message.fields))

        // Add body if present
        if let body = message.body {
            // CRLF CRLF separator between headers and body
            self.append(UInt8(ascii: "\r"))
            self.append(UInt8(ascii: "\n"))
            self.append(UInt8(ascii: "\r"))
            self.append(UInt8(ascii: "\n"))

            // Body bytes
            self.append(contentsOf: [UInt8](rfc2822Body: body))
        }
    }
}
