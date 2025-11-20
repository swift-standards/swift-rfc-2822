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
        let bytes: [UInt8]
        
        /// Initialize from byte array
        ///
        /// This is the canonical initializer that directly accepts bytes.
        ///
        /// - Parameter bytes: The message body as bytes
        public init(_ bytes: [UInt8]) {
            self.bytes = bytes
        }
    }
}

extension RFC_2822.Message.Body {
    
    /// Initialize from string
    ///
    /// Convenience initializer that converts string to UTF-8 bytes.
    ///
    /// - Parameter string: The message body as string
    public init(_ string: String) {
        self.bytes = Array(string.utf8)
    }
}

extension RFC_2822.Message.Body: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}

extension RFC_2822.Message.Body: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as string for JSON compatibility
        try container.encode(String(self))
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
