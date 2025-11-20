//
//  RFC_2822.Message.Body.swift
//  swift-rfc-2822
//
//  RFC 2822 message body with canonical byte storage
//

import INCITS_4_1986

extension RFC_2822.Message {
    /// RFC 2822 message body
    ///
    /// ## Canonical Storage
    ///
    /// The body is stored as bytes (`[UInt8]`), which is the most universal
    /// representation for email message bodies:
    ///
    /// ```
    /// Body → [UInt8] (bytes) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Category Theory
    ///
    /// This follows the natural transformation pattern:
    /// - **Domain**: Message body content
    /// - **Codomain**: `[UInt8]` (canonical byte representation)
    /// - **Composition**: String is derived through UTF-8 decoding
    ///
    /// ## RFC 2822 Notes
    ///
    /// RFC 2822 Section 2.3 defines the body as:
    /// - Lines of characters with CRLF line terminators
    /// - ASCII text (with MIME extensions for other character sets)
    /// - May be encoded per MIME specifications
    ///
    /// This type stores the raw bytes without interpretation, allowing for:
    /// - ASCII text bodies
    /// - UTF-8 encoded bodies (via MIME)
    /// - Binary content (via MIME transfer encodings)
    public struct Body: Hashable, Sendable {
        /// Canonical byte storage
        private let bytes: [UInt8]

        /// Initialize from byte array
        ///
        /// This is the canonical initializer that directly accepts bytes.
        ///
        /// - Parameter bytes: The message body as bytes
        public init(_ bytes: [UInt8]) {
            self.bytes = bytes
        }

        /// Initialize from string
        ///
        /// Convenience initializer that converts string to UTF-8 bytes.
        ///
        /// - Parameter string: The message body as string
        public init(_ string: String) {
            self.bytes = Array(string.utf8)
        }

        /// The raw bytes
        public var rawBytes: [UInt8] {
            bytes
        }
    }
}

// MARK: - Serialization

extension [UInt8] {
    /// Creates byte representation of RFC 2822 message body
    ///
    /// This is the identity transformation - the body is already stored as bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the canonical serialization (natural transformation):
    /// ```
    /// Body → [UInt8] (identity)
    /// ```
    ///
    /// - Parameter body: The message body
    public init(rfc2822Body body: RFC_2822.Message.Body) {
        self = body.rawBytes
    }
}

extension String {
    /// Creates string representation of RFC 2822 message body
    ///
    /// This composes through the canonical byte representation:
    /// ```
    /// Body → [UInt8] (canonical) → String (UTF-8 decode)
    /// ```
    ///
    /// ## Category Theory
    ///
    /// This is functor composition - String is derived from the more
    /// universal `[UInt8]` representation. UTF-8 decoding is always safe
    /// (invalid sequences are replaced with U+FFFD).
    ///
    /// - Parameter body: The message body
    public init(rfc2822Body body: RFC_2822.Message.Body) {
        // Compose through canonical byte representation
        self.init(decoding: [UInt8](rfc2822Body: body), as: UTF8.self)
    }
}

// MARK: - Protocol Conformances

extension RFC_2822.Message.Body: CustomStringConvertible {
    public var description: String {
        String(rfc2822Body: self)
    }
}

extension RFC_2822.Message.Body: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as string for JSON compatibility
        try container.encode(String(rfc2822Body: self))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string)
    }
}

extension RFC_2822.Message.Body: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
