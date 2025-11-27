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

extension RFC_2822 {
    /// Represents an email address as defined in RFC 2822 Section 3.4
    ///
    /// Per RFC 2822:
    /// ```
    /// address = mailbox / group
    /// group = display-name ":" [mailbox-list / CFWS] ";"
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Mailbox address
    /// let addr1 = try RFC_2822.Address(ascii: "john@example.com".utf8)
    ///
    /// // Group address
    /// let addr2 = try RFC_2822.Address(ascii: "Team: john@example.com, jane@example.com;".utf8)
    /// ```
    public struct Address: Sendable, Codable {
        public enum Kind: Hashable, Sendable, Codable {
            case mailbox(Mailbox)
            case group(String, [Mailbox])  // Display name and members
        }

        public let kind: Kind

        /// Creates an address WITHOUT validation
        init(__unchecked: Void, kind: Kind) {
            self.kind = kind
        }

        /// Creates an address with the given kind
        public init(_ kind: Kind) {
            self.init(__unchecked: (), kind: kind)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.Address: Hashable {}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Address: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during address parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case invalidMailbox(RFC_2822.Mailbox.Error)
        case invalidGroup(_ value: String)
        case missingGroupTerminator(_ value: String)

        public var description: String {
            switch self {
            case .empty:
                return "Address cannot be empty"
            case .invalidMailbox(let error):
                return "Invalid mailbox: \(error)"
            case .invalidGroup(let value):
                return "Invalid group format: '\(value)'"
            case .missingGroupTerminator(let value):
                return "Missing ';' terminator in group: '\(value)'"
            }
        }
    }

    /// Parses an address from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3.4
    ///
    /// ```
    /// address = mailbox / group
    /// group = display-name ":" [mailbox-list / CFWS] ";"
    /// ```
    ///
    /// - Parameter bytes: The address as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Check if this is a group (contains : but not within angle brackets)
        var inAngleBracket = false
        var colonIndex: Int? = nil
        var semicolonIndex: Int? = nil

        for (index, byte) in byteArray.enumerated() {
            if byte == UInt8.ascii.lessThanSign {
                inAngleBracket = true
            } else if byte == UInt8.ascii.greaterThanSign {
                inAngleBracket = false
            } else if byte == UInt8.ascii.colon && !inAngleBracket && colonIndex == nil {
                colonIndex = index
            } else if byte == UInt8.ascii.semicolon && colonIndex != nil {
                semicolonIndex = index
                break
            }
        }

        if let colonIdx = colonIndex {
            // This is a group: "display-name: mailbox-list ;"
            guard let semiIdx = semicolonIndex else {
                throw Error.missingGroupTerminator(String(decoding: bytes, as: UTF8.self))
            }

            // Extract display name (everything before :) and trim whitespace
            var displayNameBytes = Array(byteArray[..<colonIdx])
            while !displayNameBytes.isEmpty &&
                  (displayNameBytes.first == .ascii.space || displayNameBytes.first == .ascii.htab) {
                displayNameBytes.removeFirst()
            }
            while !displayNameBytes.isEmpty &&
                  (displayNameBytes.last == .ascii.space || displayNameBytes.last == .ascii.htab) {
                displayNameBytes.removeLast()
            }

            var displayName: String
            // Remove quotes if present
            if !displayNameBytes.isEmpty &&
               displayNameBytes.first == .ascii.quotationMark &&
               displayNameBytes.last == .ascii.quotationMark {
                displayName = String(decoding: displayNameBytes[1..<(displayNameBytes.count - 1)], as: UTF8.self)
            } else {
                displayName = String(decoding: displayNameBytes, as: UTF8.self)
            }

            // Extract mailbox list (between : and ;)
            let mailboxListStart = byteArray.index(after: colonIdx)
            let mailboxListBytes = byteArray[mailboxListStart..<semiIdx]

            // Parse mailbox list (comma-separated)
            var mailboxes: [RFC_2822.Mailbox] = []

            if !mailboxListBytes.isEmpty {
                // Split by commas (but not within angle brackets or quotes)
                var currentMailbox: [UInt8] = []
                var inQuote = false
                var inBracket = false

                for byte in mailboxListBytes {
                    if byte == UInt8.ascii.quotationMark && !inBracket {
                        inQuote.toggle()
                        currentMailbox.append(byte)
                    } else if byte == UInt8.ascii.lessThanSign && !inQuote {
                        inBracket = true
                        currentMailbox.append(byte)
                    } else if byte == UInt8.ascii.greaterThanSign && !inQuote {
                        inBracket = false
                        currentMailbox.append(byte)
                    } else if byte == UInt8.ascii.comma && !inQuote && !inBracket {
                        // End of this mailbox - trim whitespace
                        var trimmed = currentMailbox
                        while !trimmed.isEmpty && (trimmed.first == .ascii.space || trimmed.first == .ascii.htab) {
                            trimmed.removeFirst()
                        }
                        while !trimmed.isEmpty && (trimmed.last == .ascii.space || trimmed.last == .ascii.htab) {
                            trimmed.removeLast()
                        }
                        if !trimmed.isEmpty {
                            do {
                                let mailbox = try RFC_2822.Mailbox(ascii: trimmed)
                                mailboxes.append(mailbox)
                            } catch {
                                throw Error.invalidMailbox(error)
                            }
                        }
                        currentMailbox = []
                    } else {
                        currentMailbox.append(byte)
                    }
                }

                // Don't forget the last mailbox - trim whitespace
                var trimmed = currentMailbox
                while !trimmed.isEmpty && (trimmed.first == .ascii.space || trimmed.first == .ascii.htab) {
                    trimmed.removeFirst()
                }
                while !trimmed.isEmpty && (trimmed.last == .ascii.space || trimmed.last == .ascii.htab) {
                    trimmed.removeLast()
                }
                if !trimmed.isEmpty {
                    do {
                        let mailbox = try RFC_2822.Mailbox(ascii: trimmed)
                        mailboxes.append(mailbox)
                    } catch {
                        throw Error.invalidMailbox(error)
                    }
                }
            }

            self.init(__unchecked: (), kind: .group(displayName, mailboxes))
        } else {
            // This is a mailbox
            do {
                let mailbox = try RFC_2822.Mailbox(ascii: bytes)
                self.init(__unchecked: (), kind: .mailbox(mailbox))
            } catch {
                throw Error.invalidMailbox(error)
            }
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Address: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Address: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Address
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Address → [UInt8]
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
            self.append(.ascii.colon)

            for (index, mailbox) in mailboxes.enumerated() {
                if index > 0 {
                    self.append(.ascii.comma)
                    self.append(.ascii.space)
                } else {
                    self.append(.ascii.space)
                }
                self.append(contentsOf: [UInt8](mailbox))
            }

            self.append(.ascii.semicolon)
        }
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Address
    ///
    /// - Parameter address: The address to convert
    public init(_ address: RFC_2822.Address) {
        self = Self(decoding: address.bytes, as: UTF8.self)
    }
}
