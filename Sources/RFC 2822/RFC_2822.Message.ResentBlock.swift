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
