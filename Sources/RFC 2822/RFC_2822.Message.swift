//
//  RFC_2822.Message.swift
//  swift-rfc-2822
//
//  RFC 2822 message structure
//

import INCITS_4_1986

extension RFC_2822 {
    /// RFC 2822 compliant message
    public struct Message: Hashable, Sendable, Codable {
        public let fields: Fields
        public let body: Body?

        /// Canonical initializer
        public init(fields: Fields, body: Body? = nil) {
            self.fields = fields
            self.body = body
        }
    }
}

// MARK: - Convenience Initializers

extension RFC_2822.Message {
    /// Convenience initializer with string body
    public init(fields: RFC_2822.Fields, body: String?) {
        self.fields = fields
        self.body = body.map { Body.init($0) }
    }
}

// MARK: - Message Nested Types

extension RFC_2822.Message {
    /// Message identifier as defined in RFC 2822 3.6.4
    public struct ID: Hashable, Sendable, Codable, CustomStringConvertible {
        public let idLeft: String
        public let idRight: String

        public init(idLeft: String, idRight: String) {
            self.idLeft = idLeft
            self.idRight = idRight
        }

        public var description: String {
            "<\(idLeft)@\(idRight)>"
        }
    }

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
        var result = fields.description
        if let body = body {
            result += "\r\n\r\n" + String(rfc2822Body: body)
        }
        return result
    }
}
