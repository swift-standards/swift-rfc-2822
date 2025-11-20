//
//  RFC_2822.Address.swift
//  swift-rfc-2822
//
//  RFC 2822 email address representation
//

extension RFC_2822 {
    /// Represents an email address as defined in RFC 2822 Section 3.4
    public struct Address: Hashable, Sendable, Codable {
        public enum Kind: Hashable, Sendable, Codable {
            case mailbox(Mailbox)
            case group(String, [Mailbox])  // Display name and members
        }

        public let kind: Kind

        public init(_ kind: Kind) {
            self.kind = kind
        }
    }
}
