//
//  RFC_2822.Fields.swift
//  swift-rfc-2822
//
//  RFC 2822 message fields
//

extension RFC_2822 {
    /// Message fields as defined in RFC 2822 Section 3.6
    public struct Fields: Hashable, Sendable, Codable {
        // Required fields
        public let originationDate: RFC_2822.Timestamp
        public let from: [Mailbox]

        // Optional originator fields
        public let sender: Mailbox?
        public let replyTo: [Address]?

        // Optional destination fields
        public let to: [Address]?
        public let cc: [Address]?
        public let bcc: [Address]?

        // Optional identification fields
        public let messageID: Message.ID?
        public let inReplyTo: [Message.ID]?
        public let references: [Message.ID]?

        // Optional informational fields
        public let subject: String?
        public let comments: String?
        public let keywords: [String]?

        // Trace fields (optional but important)
        public let receivedFields: [Message.Received]
        public let returnPath: Message.Path?

        // Resent fields (optional block)
        public let resentFields: [Message.ResentBlock]

        public init(
            originationDate: RFC_2822.Timestamp,
            from: [Mailbox],
            sender: Mailbox? = nil,
            replyTo: [Address]? = nil,
            to: [Address]? = nil,
            cc: [Address]? = nil,
            bcc: [Address]? = nil,
            messageID: Message.ID? = nil,
            inReplyTo: [Message.ID]? = nil,
            references: [Message.ID]? = nil,
            subject: String? = nil,
            comments: String? = nil,
            keywords: [String]? = nil,
            receivedFields: [Message.Received] = [],
            returnPath: Message.Path? = nil,
            resentFields: [Message.ResentBlock] = []
        ) {
            self.originationDate = originationDate
            self.from = from
            self.sender = sender
            self.replyTo = replyTo
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.messageID = messageID
            self.inReplyTo = inReplyTo
            self.references = references
            self.subject = subject
            self.comments = comments
            self.keywords = keywords
            self.receivedFields = receivedFields
            self.returnPath = returnPath
            self.resentFields = resentFields

            // Validate sender field requirement per RFC 2822 3.6.2
            if from.count > 1 && sender == nil {
                // RFC 2822 requires sender field when from has multiple mailboxes
                assertionFailure("Sender field required when From contains multiple mailboxes")
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.Fields: CustomStringConvertible {
    public var description: String {
        var fields: [String] = []

        // Add fields in recommended order
        receivedFields.forEach { fields.append("Received: \($0)") }
        if let returnPath = returnPath {
            fields.append("Return-Path: \(returnPath)")
        }

        // Add resent blocks
        resentFields.forEach { block in
            fields.append("Resent-Date: \(block.timestamp.secondsSinceEpoch)")
            fields.append("Resent-From: \(block.from.map(\.description).joined(separator: ", "))")
            if let sender = block.sender {
                fields.append("Resent-Sender: \(sender)")
            }
            // Add other resent fields...
        }

        // Add required fields
        fields.append("Date: \(originationDate.secondsSinceEpoch)")
        fields.append("From: \(from.map(\.description).joined(separator: ", "))")

        // Add optional fields...
        if let sender = sender {
            fields.append("Sender: \(sender)")
        }

        // Join with CRLF
        return fields.joined(separator: "\r\n")
    }
}
