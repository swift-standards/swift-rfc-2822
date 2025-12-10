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
    /// RFC 2822 mailbox (name-addr or addr-spec)
    ///
    /// Per RFC 2822 Section 3.4, a mailbox is either:
    /// - name-addr: `display-name angle-addr` (e.g., "John Doe <john@example.com>")
    /// - addr-spec: `local-part@domain` (e.g., "john@example.com")
    ///
    /// ## Example
    ///
    /// ```swift
    /// // With display name
    /// let mailbox1 = try RFC_2822.Mailbox(ascii: "John Doe <john@example.com>".utf8)
    /// print(mailbox1.displayName) // "John Doe"
    ///
    /// // Without display name
    /// let mailbox2 = try RFC_2822.Mailbox(ascii: "john@example.com".utf8)
    /// print(mailbox2.displayName) // nil
    /// ```
    ///
    /// ## See Also
    ///
    /// - [RFC 2822 Section 3.4](https://www.rfc-editor.org/rfc/rfc2822#section-3.4)
    public struct Mailbox: Hashable, Sendable, Codable {
        public let displayName: String?
        public let emailAddress: AddrSpec

        /// Creates a mailbox WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 2822 validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(__unchecked: Void, displayName: String?, emailAddress: AddrSpec) {
            self.displayName = displayName
            self.emailAddress = emailAddress
        }

        /// Creates a validated mailbox
        ///
        /// - Parameters:
        ///   - displayName: Optional display name (e.g., "John Doe")
        ///   - emailAddress: The email address
        public init(displayName: String? = nil, emailAddress: AddrSpec) {
            self.init(__unchecked: (), displayName: displayName, emailAddress: emailAddress)
        }
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_2822.Mailbox: Binary.ASCII.Serializable {
    /// Serialize to canonical ASCII byte representation
    ///
    /// Formats as either "Display Name <addr-spec>" or just "addr-spec".
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii mailbox: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        if let displayName = mailbox.displayName {
            // Check if display name needs quoting
            let needsQuoting = displayName.utf8.contains { byte in
                !byte.ascii.isLetter && !byte.ascii.isDigit && byte != .ascii.space
            }

            if needsQuoting {
                buffer.append(.ascii.quotationMark)
                buffer.append(contentsOf: displayName.utf8)
                buffer.append(.ascii.quotationMark)
            } else {
                buffer.append(contentsOf: displayName.utf8)
            }

            buffer.append(.ascii.space)
            buffer.append(.ascii.lessThanSign)
            RFC_2822.AddrSpec.serialize(ascii: mailbox.emailAddress, into: &buffer)
            buffer.append(.ascii.greaterThanSign)
        } else {
            // Just the addr-spec
            RFC_2822.AddrSpec.serialize(ascii: mailbox.emailAddress, into: &buffer)
        }
    }

    /// Parses a mailbox from ASCII bytes
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2822.Mailbox (structured data)
    ///
    /// ## Format
    ///
    /// Supports two formats:
    /// - `Display Name <addr-spec>` (name-addr)
    /// - `addr-spec` (simple address)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("John Doe <john@example.com>".utf8)
    /// let mailbox = try RFC_2822.Mailbox(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The mailbox as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Check if this is a name-addr format (contains angle brackets)
        if let openIndex = byteArray.lastIndex(of: .ascii.lessThanSign) {
            // name-addr format: "Display Name <addr-spec>"
            guard let closeIndex = byteArray.lastIndex(of: .ascii.greaterThanSign),
                closeIndex > openIndex
            else {
                throw Error.missingClosingAngleBracket(String(decoding: bytes, as: UTF8.self))
            }

            // Extract display name (everything before <)
            let displayNameBytes = byteArray[..<openIndex]

            // Trim whitespace from display name (byte level)
            var trimmedDisplayNameBytes = Array(displayNameBytes)
            while !trimmedDisplayNameBytes.isEmpty
                && (trimmedDisplayNameBytes.first == .ascii.space
                    || trimmedDisplayNameBytes.first == .ascii.htab) {
                trimmedDisplayNameBytes.removeFirst()
            }
            while !trimmedDisplayNameBytes.isEmpty
                && (trimmedDisplayNameBytes.last == .ascii.space
                    || trimmedDisplayNameBytes.last == .ascii.htab) {
                trimmedDisplayNameBytes.removeLast()
            }

            var displayName = String(decoding: trimmedDisplayNameBytes, as: UTF8.self)

            // Remove quotes if present
            if !trimmedDisplayNameBytes.isEmpty
                && trimmedDisplayNameBytes.first == .ascii.quotationMark
                && trimmedDisplayNameBytes.last == .ascii.quotationMark {
                displayName = String(
                    decoding: trimmedDisplayNameBytes[1..<(trimmedDisplayNameBytes.count - 1)],
                    as: UTF8.self
                )
            }

            // Extract addr-spec (between < and >)
            let addrSpecStart = byteArray.index(after: openIndex)
            let addrSpecBytes = byteArray[addrSpecStart..<closeIndex]

            let emailAddress: RFC_2822.AddrSpec
            do {
                emailAddress = try RFC_2822.AddrSpec(ascii: addrSpecBytes)
            } catch {
                throw Error.invalidAddrSpec(error)
            }

            self.init(
                __unchecked: (),
                displayName: displayName.isEmpty ? nil : displayName,
                emailAddress: emailAddress
            )
        } else {
            // addr-spec format (no display name)
            let emailAddress: RFC_2822.AddrSpec
            do {
                emailAddress = try RFC_2822.AddrSpec(ascii: bytes)
            } catch {
                throw Error.invalidAddrSpec(error)
            }

            self.init(__unchecked: (), displayName: nil, emailAddress: emailAddress)
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Mailbox: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}

extension RFC_2822.Mailbox: CustomStringConvertible {}

extension [UInt8] {
    /// Creates byte representation of RFC 2822 Mailbox
    ///
    /// Formats as either "Display Name <addr-spec>" or just "addr-spec".
    ///
    /// ## Category Theory
    ///
    /// Natural transformation: RFC_2822.Mailbox → [UInt8]
    ///
    /// - Parameter mailbox: The mailbox to serialize
    public init(_ mailbox: RFC_2822.Mailbox) {
        self = []

        if let displayName = mailbox.displayName {
            // Check if display name needs quoting
            let needsQuoting = displayName.contains(where: {
                !$0.ascii.isLetter && !$0.ascii.isDigit
            })

            if needsQuoting {
                self.append(.ascii.quotationMark)
                self.append(utf8: displayName)
                self.append(.ascii.quotationMark)
            } else {
                self.append(contentsOf: displayName.utf8)
            }

            self.append(.ascii.space)
            self.append(.ascii.lessThanSign)
            self.append(mailbox.emailAddress)
            self.append(.ascii.greaterThanSign)
        } else {
            // Just the addr-spec
            self.append(mailbox.emailAddress)
        }
    }
}
