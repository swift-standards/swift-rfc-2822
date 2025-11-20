//
//  RFC_2822.Mailbox.swift
//  swift-rfc-2822
//
//  RFC 2822 mailbox address
//

import INCITS_4_1986

extension RFC_2822 {
    /// Represents a mailbox address (name-addr or addr-spec)
    public struct Mailbox: Hashable, Sendable, Codable {
        public let displayName: String?
        public let emailAddress: AddrSpec

        public init(displayName: String? = nil, emailAddress: AddrSpec) {
            self.displayName = displayName
            self.emailAddress = emailAddress
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.Mailbox: CustomStringConvertible {
    public var description: String {
        if let name = displayName {
            // Quote display name if it contains special characters
            let needsQuoting = name.contains(where: { !$0.isASCIILetter && !$0.isASCIIDigit })
            let formattedName = needsQuoting ? "\"\(name)\"" : name
            return "\(formattedName) <\(emailAddress)>"
        }
        return emailAddress.description
    }
}
