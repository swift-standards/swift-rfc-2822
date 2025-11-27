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
    /// RFC 2822 compliant message
    ///
    /// Per RFC 2822 Section 3:
    /// ```
    /// message = (fields / obs-fields) [CRLF body]
    /// body = *(*998text CRLF) *998text
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let message = try RFC_2822.Message(ascii: rawMessageBytes)
    /// print(message.fields.subject)
    /// print(message.body)
    /// ```
    public struct Message: Sendable, Codable {
        public let fields: Fields
        public let body: Body?

        /// Creates a message WITHOUT validation
        init(__unchecked: Void, fields: Fields, body: Body?) {
            self.fields = fields
            self.body = body
        }

        /// Canonical initializer
        public init(fields: Fields, body: Body? = nil) {
            self.init(__unchecked: (), fields: fields, body: body)
        }
    }
}

// MARK: - Hashable

extension RFC_2822.Message: Hashable {}

// MARK: - Convenience Initializers

extension RFC_2822.Message {
    /// Convenience initializer with string body
    public init(fields: RFC_2822.Fields, body: String?) {
        self.init(__unchecked: (), fields: fields, body: body.map { Body($0) })
    }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_2822.Message: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

    /// Errors during message parsing
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        case empty
        case invalidFields(RFC_2822.Fields.Error)

        public var description: String {
            switch self {
            case .empty:
                return "Message cannot be empty"
            case .invalidFields(let error):
                return "Invalid fields: \(error)"
            }
        }
    }

    /// Parses a message from ASCII bytes (AUTHORITATIVE IMPLEMENTATION)
    ///
    /// ## RFC 2822 Section 3
    ///
    /// ```
    /// message = (fields / obs-fields) [CRLF body]
    /// ```
    ///
    /// Headers and body are separated by a blank line (CRLF CRLF).
    ///
    /// - Parameter bytes: The message as ASCII bytes
    /// - Throws: `Error` if parsing fails
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.empty }

        let byteArray = Array(bytes)

        // Find the blank line (CRLF CRLF) that separates headers from body
        var headerEndIndex: Int?
        var bodyStartIndex: Int?

        // Look for CRLF CRLF
        for i in 0..<(byteArray.count - 3) {
            if byteArray[i] == .ascii.cr && byteArray[i + 1] == .ascii.lf
                && byteArray[i + 2] == .ascii.cr && byteArray[i + 3] == .ascii.lf {
                headerEndIndex = i
                bodyStartIndex = i + 4
                break
            }
        }

        // If not found, try LF LF (lenient)
        if headerEndIndex == nil {
            for i in 0..<(byteArray.count - 1) {
                if byteArray[i] == .ascii.lf && byteArray[i + 1] == .ascii.lf {
                    headerEndIndex = i
                    bodyStartIndex = i + 2
                    break
                }
            }
        }

        // Parse fields
        let fieldsBytes: [UInt8]
        let bodyBytes: [UInt8]?

        if let headerEnd = headerEndIndex, let bodyStart = bodyStartIndex {
            fieldsBytes = Array(byteArray[..<headerEnd])
            if bodyStart < byteArray.count {
                bodyBytes = Array(byteArray[bodyStart...])
            } else {
                bodyBytes = nil
            }
        } else {
            // No blank line - treat entire input as headers
            fieldsBytes = byteArray
            bodyBytes = nil
        }

        let fields: RFC_2822.Fields
        do {
            fields = try RFC_2822.Fields(ascii: fieldsBytes)
        } catch {
            throw Error.invalidFields(error)
        }

        let body: Body? = bodyBytes.flatMap { bytes in
            bytes.isEmpty ? nil : Body(bytes)
        }

        self.init(__unchecked: (), fields: fields, body: body)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

// MARK: - CustomStringConvertible

extension RFC_2822.Message: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

// MARK: - [UInt8] Conversion

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
    /// - Parameter message: The RFC 2822 message to serialize
    public init(_ message: RFC_2822.Message) {
        self = []

        // Serialize fields
        self.append(contentsOf: [UInt8](message.fields))

        // Add body if present
        if let body = message.body {
            // CRLF CRLF separator between headers and body
            self.append(.ascii.cr)
            self.append(.ascii.lf)
            self.append(.ascii.cr)
            self.append(.ascii.lf)

            // Body bytes
            self.append(contentsOf: body.bytes)
        }
    }
}

// MARK: - StringProtocol Conversion

extension StringProtocol {
    /// Create a string from an RFC 2822 Message
    ///
    /// - Parameter message: The message to convert
    public init(_ message: RFC_2822.Message) {
        self = Self(decoding: message.bytes, as: UTF8.self)
    }
}
