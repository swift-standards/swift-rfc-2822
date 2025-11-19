//
//  File.swift
//  swift-web-standards
//
//  Created by Coen ten Thije Boonkkamp on 02/02/2025.
//

import INCITS_4_1986

public enum RFC_2822 {}

extension RFC_2822 {
    /// RFC 2822 compliant message
    public struct Message: Hashable, Sendable, Codable {
        public let fields: Fields
        public let body: String?

        public init(fields: Fields, body: String? = nil) {
            self.fields = fields
            self.body = body
        }
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

extension RFC_2822 {
    /// Represents an addr-spec (local-part@domain)
    public struct AddrSpec: Hashable, Sendable, Codable {
        public let localPart: String
        public let domain: String

        public init(localPart: String, domain: String) throws {
            // Validate local-part and domain according to RFC 2822 3.4.1
            guard Self.validateLocalPart(localPart) else {
                throw ValidationError.invalidLocalPart(localPart)
            }

            guard Self.validateDomain(domain) else {
                throw ValidationError.invalidDomain(domain)
            }

            self.localPart = localPart
            self.domain = domain
        }

        private static func validateLocalPart(_ localPart: String) -> Bool {
            guard !localPart.isEmpty else { return false }

            // Per RFC 2822 3.4.1, local-part can be dot-atom or quoted-string
            if localPart.hasPrefix("\"") && localPart.hasSuffix("\"") {
                // Quoted string validation
                let quotedContent = String(localPart.dropFirst().dropLast())

                // Check for valid qtext or quoted-pair
                var isEscaped = false
                for char in quotedContent {
                    if isEscaped {
                        // After backslash, only allow certain chars to be escaped
                        guard char.isASCII && (char == "\\" || char == "\"" || char.isASCII) else {
                            return false
                        }
                        isEscaped = false
                    } else if char == "\\" {
                        isEscaped = true
                    } else {
                        // qtext = NO-WS-CTL / %d33-33 / %d35-91 / %d93-126
                        let isValidQText =
                            char.isASCII
                            && ((char.asciiValue! >= 1 && char.asciiValue! <= 8)
                                || (char.asciiValue! == 11 || char.asciiValue! == 12)
                                || (char.asciiValue! >= 14 && char.asciiValue! <= 31)
                                || char.asciiValue! == 33
                                || (char.asciiValue! >= 35 && char.asciiValue! <= 91)
                                || (char.asciiValue! >= 93 && char.asciiValue! <= 126))
                        guard isValidQText else { return false }
                    }
                }
                // Make sure we don't end with an unclosed escape
                return !isEscaped

            } else {
                // Dot-atom validation
                // Split into atoms by dots
                let atoms = localPart.split(separator: ".", omittingEmptySubsequences: false)

                // Check for empty atoms (consecutive dots or leading/trailing dots)
                guard !atoms.contains(where: { $0.isEmpty }) else { return false }

                // Validate each atom
                return atoms.allSatisfy { atom in
                    atom.allSatisfy { char in
                        // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
                        char.isASCIILetter || char.isASCIIDigit || "!#$%&'*+-/=?^_`{|}~".contains(char)
                    }
                }
            }
        }

        private static func validateDomain(_ domain: String) -> Bool {
            guard !domain.isEmpty else { return false }

            // Domain can be dot-atom or domain-literal
            if domain.hasPrefix("[") && domain.hasSuffix("]") {
                // Domain-literal validation
                let literalContent = String(domain.dropFirst().dropLast())

                var isEscaped = false
                for char in literalContent {
                    if isEscaped {
                        // After backslash, only certain chars can be escaped
                        guard char == "[" || char == "]" || char == "\\" else {
                            return false
                        }
                        isEscaped = false
                    } else if char == "\\" {
                        isEscaped = true
                    } else {
                        // dtext = NO-WS-CTL / %d33-90 / %d94-126
                        let isValidDText =
                            char.isASCII
                            && ((char.asciiValue! >= 1 && char.asciiValue! <= 8)
                                || (char.asciiValue! == 11 || char.asciiValue! == 12)
                                || (char.asciiValue! >= 14 && char.asciiValue! <= 31)
                                || (char.asciiValue! >= 33 && char.asciiValue! <= 90)
                                || (char.asciiValue! >= 94 && char.asciiValue! <= 126))
                        guard isValidDText else { return false }
                    }
                }
                // Make sure we don't end with an unclosed escape
                return !isEscaped

            } else {
                // Dot-atom validation
                // Split into atoms by dots
                let atoms = domain.split(separator: ".", omittingEmptySubsequences: false)

                // Check for empty atoms (consecutive dots or leading/trailing dots)
                guard !atoms.contains(where: { $0.isEmpty }) else { return false }

                // Must have at least one dot (at least two atoms)
                guard atoms.count >= 2 else { return false }

                // Validate each atom
                return atoms.allSatisfy { atom in
                    atom.allSatisfy { char in
                        // RFC 1035 restrictions for domain labels:
                        // - Start with letter
                        // - End with letter or digit
                        // - Interior chars can be letter, digit, or hyphen
                        if atom.first == char {
                            return char.isASCIILetter
                        } else if atom.last == char {
                            return char.isASCIILetter || char.isASCIIDigit
                        } else {
                            return char.isASCIILetter || char.isASCIIDigit || char == "-"
                        }
                    }
                }
            }
        }
    }
}

extension RFC_2822 {
    public enum ValidationError: Error {
        case invalidLocalPart(String)
        case invalidDomain(String)
        case missingRequiredField(String)
        case invalidFieldValue(String, String)
    }

}

// MARK: - CustomStringConvertible Conformance

extension RFC_2822.Message: CustomStringConvertible {
    public var description: String {
        var result = fields.description
        if let body = body {
            result += "\r\n\r\n" + body
        }
        return result
    }
}

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

extension RFC_2822.AddrSpec: CustomStringConvertible {
    public var description: String {
        "\(localPart)@\(domain)"
    }
}
