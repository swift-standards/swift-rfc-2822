//
//  RFC_2822.swift
//  swift-rfc-2822
//
//  RFC 2822 Internet Message Format namespace
//

import INCITS_4_1986

/// RFC 2822 Internet Message Format
///
/// This namespace contains types for working with RFC 2822 email messages.
///
/// ## Key Types
///
/// - `Message`: Complete RFC 2822 message (fields + body)
/// - `Fields`: Message header fields
/// - `Mailbox`: Email mailbox (name + address)
/// - `Address`: Email address (mailbox or group)
/// - `AddrSpec`: Address specification (local-part@domain)
/// - `Timestamp`: RFC 2822 timestamp
///
/// ## Canonical Architecture
///
/// All types follow canonical byte-based serialization:
/// - Storage: `[UInt8]` for body content
/// - Serialization: Direct byte generation without intermediate allocations
/// - String: Derived through functor composition from bytes
public enum RFC_2822 {}

// MARK: - atext Character Set

extension RFC_2822 {
    /// ASCII symbol bytes allowed in `atext` per RFC 2822 Section 3.2.4
    ///
    /// The `atext` rule defines printable US-ASCII characters that can appear in atoms:
    /// ```
    /// atext = ALPHA / DIGIT /    ; Any character except controls,
    ///         "!" / "#" /        ;  SP, and specials.
    ///         "$" / "%" /        ;  Used for atoms
    ///         "&" / "'" /
    ///         "*" / "+" /
    ///         "-" / "/" /
    ///         "=" / "?" /
    ///         "^" / "_" /
    ///         "`" / "{" /
    ///         "|" / "}" /
    ///         "~"
    /// ```
    ///
    /// This set contains only the special symbols; ALPHA and DIGIT should be checked
    /// separately using `byte.ascii.isLetter` and `byte.ascii.isDigit`.
    public static let atextSymbols: Set<UInt8> = [
        UInt8.ascii.exclamationPoint,  // ! (0x21)
        UInt8.ascii.numberSign,  // # (0x23)
        UInt8.ascii.dollarSign,  // $ (0x24)
        UInt8.ascii.percentSign,  // % (0x25)
        UInt8.ascii.ampersand,  // & (0x26)
        UInt8.ascii.apostrophe,  // ' (0x27)
        UInt8.ascii.asterisk,  // * (0x2A)
        UInt8.ascii.plusSign,  // + (0x2B)
        UInt8.ascii.hyphen,  // - (0x2D)
        UInt8.ascii.solidus,  // / (0x2F)
        UInt8.ascii.equalsSign,  // = (0x3D)
        UInt8.ascii.questionMark,  // ? (0x3F)
        UInt8.ascii.circumflexAccent,  // ^ (0x5E)
        UInt8.ascii.underline,  // _ (0x5F)
        UInt8.ascii.leftSingleQuotationMark,  // ` (0x60)
        UInt8.ascii.leftBrace,  // { (0x7B)
        UInt8.ascii.verticalLine,  // | (0x7C)
        UInt8.ascii.rightBrace,  // } (0x7D)
        UInt8.ascii.tilde,  // ~ (0x7E)
    ]

    /// Tests if an ASCII byte is a valid `atext` character per RFC 2822 Section 3.2.4
    ///
    /// Returns `true` if the byte is ALPHA, DIGIT, or one of the allowed symbols.
    ///
    /// - Parameter byte: The ASCII byte to test
    /// - Returns: `true` if the byte is valid in an atom
    @inlinable
    public static func isAtext(_ byte: UInt8) -> Bool {
        byte.ascii.isLetter || byte.ascii.isDigit || atextSymbols.contains(byte)
    }
}
