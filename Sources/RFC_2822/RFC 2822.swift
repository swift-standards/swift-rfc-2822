//
//  File.swift
//  swift-web-standards
//
//  Created by Coen ten Thije Boonkkamp on 02/02/2025.
//

import Foundation

extension RFC_2822 {
    /// RFC 2822 compliant message
    public struct Message: Hashable, Sendable {
        public let fields: Fields
        public let body: String?

        public init(fields: Fields, body: String? = nil) {
            self.fields = fields
            self.body = body
        }
    }
}

extension RFC_2822 {
    /// Message fields as defined in RFC 2822 Section 3.6
    public struct Fields: Hashable, Sendable {
        // Required fields
        public let originationDate: Foundation.Date
        public let from: [Mailbox]

        // Optional originator fields
        public let sender: Mailbox?
        public let replyTo: [Address]?

        // Optional destination fields
        public let to: [Address]?
        public let cc: [Address]?
        public let bcc: [Address]?

        // Optional identification fields
        public let messageID: MessageID?
        public let inReplyTo: [MessageID]?
        public let references: [MessageID]?

        // Optional informational fields
        public let subject: String?
        public let comments: String?
        public let keywords: [String]?

        // Trace fields (optional but important)
        public let receivedFields: [Received]
        public let returnPath: Path?

        // Resent fields (optional block)
        public let resentFields: [ResentBlock]

        public init(
            originationDate: Foundation.Date,
            from: [Mailbox],
            sender: Mailbox? = nil,
            replyTo: [Address]? = nil,
            to: [Address]? = nil,
            cc: [Address]? = nil,
            bcc: [Address]? = nil,
            messageID: MessageID? = nil,
            inReplyTo: [MessageID]? = nil,
            references: [MessageID]? = nil,
            subject: String? = nil,
            comments: String? = nil,
            keywords: [String]? = nil,
            receivedFields: [Received] = [],
            returnPath: Path? = nil,
            resentFields: [ResentBlock] = []
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
    public struct Address: Hashable, Sendable {
        public enum Kind: Hashable, Sendable {
            case mailbox(Mailbox)
            case group(String, [Mailbox]) // Display name and members
        }

        public let kind: Kind

        public init(_ kind: Kind) {
            self.kind = kind
        }
    }
}

extension RFC_2822 {
    /// Represents a mailbox address (name-addr or addr-spec)
    public struct Mailbox: Hashable, Sendable {
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
    public struct AddrSpec: Hashable, Sendable {
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
                        let isValidQText = char.isASCII && (
                            (char.asciiValue! >= 1 && char.asciiValue! <= 8) ||
                            (char.asciiValue! == 11 || char.asciiValue! == 12) ||
                            (char.asciiValue! >= 14 && char.asciiValue! <= 31) ||
                            char.asciiValue! == 33 ||
                            (char.asciiValue! >= 35 && char.asciiValue! <= 91) ||
                            (char.asciiValue! >= 93 && char.asciiValue! <= 126)
                        )
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
                        char.isLetter || char.isNumber ||
                        "!#$%&'*+-/=?^_`{|}~".contains(char)
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
                        let isValidDText = char.isASCII && (
                            (char.asciiValue! >= 1 && char.asciiValue! <= 8) ||
                            (char.asciiValue! == 11 || char.asciiValue! == 12) ||
                            (char.asciiValue! >= 14 && char.asciiValue! <= 31) ||
                            (char.asciiValue! >= 33 && char.asciiValue! <= 90) ||
                            (char.asciiValue! >= 94 && char.asciiValue! <= 126)
                        )
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
                            return char.isLetter
                        } else if atom.last == char {
                            return char.isLetter || char.isNumber
                        } else {
                            return char.isLetter || char.isNumber || char == "-"
                        }
                    }
                }
            }
        }
    }
}

extension RFC_2822 {
    /// Message identifier as defined in RFC 2822 3.6.4
    public struct MessageID: Hashable, Sendable {
        public let idLeft: String
        public let idRight: String

        public init(idLeft: String, idRight: String) {
            self.idLeft = idLeft
            self.idRight = idRight
        }

        public var stringValue: String {
            "<\(idLeft)@\(idRight)>"
        }
    }
}

extension RFC_2822 {
    /// Return path for trace fields
    public struct Path: Hashable, Sendable {
        public let addrSpec: AddrSpec?

        public init(addrSpec: AddrSpec? = nil) {
            self.addrSpec = addrSpec
        }
    }
}

extension RFC_2822 {
    /// Received trace field
    public struct Received: Hashable, Sendable {
        public struct NameValuePair: Hashable, Sendable {
            public let name: String
            public let value: String
        }

        public let tokens: [NameValuePair]
        public let date: Foundation.Date

        public init(tokens: [NameValuePair], date: Foundation.Date) {
            self.tokens = tokens
            self.date = date
        }
    }
}

extension RFC_2822 {
    /// Block of resent fields
    public struct ResentBlock: Hashable, Sendable {
        public let date: Foundation.Date
        public let from: [Mailbox]
        public let sender: Mailbox?
        public let to: [Address]?
        public let cc: [Address]?
        public let bcc: [Address]?
        public let messageID: MessageID?

        public init(
            date: Foundation.Date,
            from: [Mailbox],
            sender: Mailbox? = nil,
            to: [Address]? = nil,
            cc: [Address]? = nil,
            bcc: [Address]? = nil,
            messageID: MessageID? = nil
        ) {
            self.date = date
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
            fields.append("Resent-Date: \(block.date)")
            fields.append("Resent-From: \(block.from.map(\.description).joined(separator: ", "))")
            if let sender = block.sender {
                fields.append("Resent-Sender: \(sender)")
            }
            // Add other resent fields...
        }

        // Add required fields
        fields.append("Date: \(RFC_2822.Date.formatter.string(from: originationDate))")
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
            let needsQuoting = name.contains(where: { !$0.isLetter && !$0.isNumber })
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
