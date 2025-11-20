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
