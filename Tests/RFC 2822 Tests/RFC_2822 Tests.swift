//
//  RFC_2822 Tests.swift
//  swift-rfc-2822
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Foundation
import Testing

@testable import RFC_2822

// MARK: - AddrSpec Tests

@Suite("RFC 2822 AddrSpec Tests")
struct AddrSpecTests {
    @Test("Successfully creates valid addr-spec")
    func testValidAddrSpec() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        #expect(addr.localPart == "user")
        #expect(addr.domain == "example.com")
    }

    @Test("Successfully creates addr-spec with subdomain")
    func testValidAddrSpecWithSubdomain() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user@mail.example.com".utf8)
        #expect(addr.localPart == "user")
        #expect(addr.domain == "mail.example.com")
    }

    @Test("Successfully creates addr-spec with dots in local part")
    func testValidAddrSpecWithDots() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "first.last@example.com".utf8)
        #expect(addr.localPart == "first.last")
    }

    @Test("Successfully creates addr-spec with plus sign")
    func testValidAddrSpecWithPlus() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user+tag@example.com".utf8)
        #expect(addr.localPart == "user+tag")
    }

    @Test("Successfully creates addr-spec with hyphen")
    func testValidAddrSpecWithHyphen() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user-name@example.com".utf8)
        #expect(addr.localPart == "user-name")
    }

    @Test("Successfully creates addr-spec with quoted local part")
    func testValidAddrSpecQuoted() throws {
        // Quoted string with valid qtext (no spaces - space requires FWS handling)
        let addr = try RFC_2822.AddrSpec(ascii: "\"user.name\"@example.com".utf8)
        #expect(addr.localPart == "\"user.name\"")
    }

    @Test("Successfully creates addr-spec with domain literal")
    func testValidAddrSpecDomainLiteral() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user@[192.168.1.1]".utf8)
        #expect(addr.domain == "[192.168.1.1]")
    }

    @Test("Fails with empty input")
    func testEmptyAddrSpec() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.empty) {
            _ = try RFC_2822.AddrSpec(ascii: "".utf8)
        }
    }

    @Test("Fails with missing @ sign")
    func testMissingAtSign() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: "userexample.com".utf8)
        }
    }

    @Test("Fails with empty local part")
    func testEmptyLocalPart() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: "@example.com".utf8)
        }
    }

    @Test("Fails with empty domain")
    func testEmptyDomain() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: "user@".utf8)
        }
    }

    @Test("Fails with local part starting with dot")
    func testLocalPartStartingWithDot() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: ".user@example.com".utf8)
        }
    }

    @Test("Fails with local part ending with dot")
    func testLocalPartEndingWithDot() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: "user.@example.com".utf8)
        }
    }

    @Test("Fails with consecutive dots in local part")
    func testConsecutiveDotsInLocalPart() throws {
        #expect(throws: RFC_2822.AddrSpec.Error.self) {
            _ = try RFC_2822.AddrSpec(ascii: "user..name@example.com".utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() throws {
        let addr1 = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        let addr2 = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        let addr3 = try RFC_2822.AddrSpec(ascii: "other@example.com".utf8)
        #expect(addr1 == addr2)
        #expect(addr1 != addr3)
    }

    @Test("Successfully tests case-insensitive domain equality")
    func testCaseInsensitiveDomain() throws {
        let addr1 = try RFC_2822.AddrSpec(ascii: "user@EXAMPLE.COM".utf8)
        let addr2 = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        #expect(addr1 == addr2)
    }

    @Test("Successfully tests hashable")
    func testHashable() throws {
        var set: Set<RFC_2822.AddrSpec> = []
        set.insert(try RFC_2822.AddrSpec(ascii: "user@example.com".utf8))
        set.insert(try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)) // Duplicate
        set.insert(try RFC_2822.AddrSpec(ascii: "other@example.com".utf8))
        #expect(set.count == 2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.AddrSpec.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Successfully serializes to string")
    func testSerialization() throws {
        let addr = try RFC_2822.AddrSpec(ascii: "user@example.com".utf8)
        #expect(String(addr) == "user@example.com")
    }
}

// MARK: - Mailbox Tests

@Suite("RFC 2822 Mailbox Tests")
struct MailboxTests {
    @Test("Successfully creates mailbox with just addr-spec")
    func testMailboxAddrSpecOnly() throws {
        let mailbox = try RFC_2822.Mailbox(ascii: "user@example.com".utf8)
        #expect(mailbox.displayName == nil)
        #expect(mailbox.emailAddress.localPart == "user")
        #expect(mailbox.emailAddress.domain == "example.com")
    }

    @Test("Successfully creates mailbox with display name")
    func testMailboxWithDisplayName() throws {
        let mailbox = try RFC_2822.Mailbox(ascii: "John Doe <john@example.com>".utf8)
        #expect(mailbox.displayName == "John Doe")
        #expect(mailbox.emailAddress.localPart == "john")
    }

    @Test("Successfully creates mailbox with quoted display name")
    func testMailboxWithQuotedDisplayName() throws {
        let mailbox = try RFC_2822.Mailbox(ascii: "\"John Q. Doe\" <john@example.com>".utf8)
        #expect(mailbox.displayName == "John Q. Doe")
    }

    @Test("Fails with empty input")
    func testEmptyMailbox() throws {
        #expect(throws: RFC_2822.Mailbox.Error.empty) {
            _ = try RFC_2822.Mailbox(ascii: "".utf8)
        }
    }

    @Test("Fails with missing closing angle bracket")
    func testMissingClosingBracket() throws {
        #expect(throws: RFC_2822.Mailbox.Error.self) {
            _ = try RFC_2822.Mailbox(ascii: "John <john@example.com".utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() throws {
        let m1 = try RFC_2822.Mailbox(ascii: "John <john@example.com>".utf8)
        let m2 = try RFC_2822.Mailbox(ascii: "John <john@example.com>".utf8)
        let m3 = try RFC_2822.Mailbox(ascii: "Jane <jane@example.com>".utf8)
        #expect(m1 == m2)
        #expect(m1 != m3)
    }

    @Test("Successfully tests hashable")
    func testHashable() throws {
        var set: Set<RFC_2822.Mailbox> = []
        set.insert(try RFC_2822.Mailbox(ascii: "john@example.com".utf8))
        set.insert(try RFC_2822.Mailbox(ascii: "john@example.com".utf8))
        set.insert(try RFC_2822.Mailbox(ascii: "jane@example.com".utf8))
        #expect(set.count == 2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try RFC_2822.Mailbox(ascii: "John <john@example.com>".utf8)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Mailbox.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Successfully serializes to string")
    func testSerialization() throws {
        let mailbox = try RFC_2822.Mailbox(ascii: "John <john@example.com>".utf8)
        let serialized = String(mailbox)
        #expect(serialized.contains("john@example.com"))
    }
}

// MARK: - Address Tests

@Suite("RFC 2822 Address Tests")
struct AddressTests {
    @Test("Successfully creates mailbox address")
    func testMailboxAddress() throws {
        let address = try RFC_2822.Address(ascii: "user@example.com".utf8)
        if case .mailbox(let mailbox) = address.kind {
            #expect(mailbox.emailAddress.localPart == "user")
        } else {
            Issue.record("Expected mailbox address")
        }
    }

    @Test("Successfully creates group address")
    func testGroupAddress() throws {
        let address = try RFC_2822.Address(ascii: "Team: john@example.com, jane@example.com;".utf8)
        if case .group(let name, let mailboxes) = address.kind {
            #expect(name == "Team")
            #expect(mailboxes.count == 2)
        } else {
            Issue.record("Expected group address")
        }
    }

    @Test("Successfully creates empty group")
    func testEmptyGroup() throws {
        let address = try RFC_2822.Address(ascii: "Empty Group:;".utf8)
        if case .group(let name, let mailboxes) = address.kind {
            #expect(name == "Empty Group")
            #expect(mailboxes.isEmpty)
        } else {
            Issue.record("Expected group address")
        }
    }

    @Test("Fails with empty input")
    func testEmptyAddress() throws {
        #expect(throws: RFC_2822.Address.Error.empty) {
            _ = try RFC_2822.Address(ascii: "".utf8)
        }
    }

    @Test("Fails with missing group terminator")
    func testMissingGroupTerminator() throws {
        #expect(throws: RFC_2822.Address.Error.self) {
            _ = try RFC_2822.Address(ascii: "Team: john@example.com".utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() throws {
        let a1 = try RFC_2822.Address(ascii: "user@example.com".utf8)
        let a2 = try RFC_2822.Address(ascii: "user@example.com".utf8)
        let a3 = try RFC_2822.Address(ascii: "other@example.com".utf8)
        #expect(a1 == a2)
        #expect(a1 != a3)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try RFC_2822.Address(ascii: "user@example.com".utf8)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Address.self, from: encoded)
        #expect(original == decoded)
    }
}

// MARK: - Message.ID Tests

@Suite("RFC 2822 Message.ID Tests")
struct MessageIDTests {
    @Test("Successfully creates valid message ID")
    func testValidMessageID() throws {
        let id = try RFC_2822.Message.ID(ascii: "<unique-id@example.com>".utf8)
        #expect(id.idLeft == "unique-id")
        #expect(id.idRight == "example.com")
    }

    @Test("Successfully creates message ID with dots")
    func testMessageIDWithDots() throws {
        let id = try RFC_2822.Message.ID(ascii: "<abc.def.123@mail.example.com>".utf8)
        #expect(id.idLeft == "abc.def.123")
        #expect(id.idRight == "mail.example.com")
    }

    @Test("Successfully creates message ID with whitespace around it")
    func testMessageIDWithWhitespace() throws {
        let id = try RFC_2822.Message.ID(ascii: "  <id@example.com>  ".utf8)
        #expect(id.idLeft == "id")
        #expect(id.idRight == "example.com")
    }

    @Test("Fails with empty input")
    func testEmptyMessageID() throws {
        #expect(throws: RFC_2822.Message.ID.Error.empty) {
            _ = try RFC_2822.Message.ID(ascii: "".utf8)
        }
    }

    @Test("Fails with missing angle brackets")
    func testMissingAngleBrackets() throws {
        #expect(throws: RFC_2822.Message.ID.Error.self) {
            _ = try RFC_2822.Message.ID(ascii: "id@example.com".utf8)
        }
    }

    @Test("Fails with missing @ sign")
    func testMissingAtSign() throws {
        #expect(throws: RFC_2822.Message.ID.Error.self) {
            _ = try RFC_2822.Message.ID(ascii: "<idexample.com>".utf8)
        }
    }

    @Test("Fails with empty id-left")
    func testEmptyIdLeft() throws {
        #expect(throws: RFC_2822.Message.ID.Error.self) {
            _ = try RFC_2822.Message.ID(ascii: "<@example.com>".utf8)
        }
    }

    @Test("Fails with empty id-right")
    func testEmptyIdRight() throws {
        #expect(throws: RFC_2822.Message.ID.Error.self) {
            _ = try RFC_2822.Message.ID(ascii: "<id@>".utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() throws {
        let id1 = try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8)
        let id2 = try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8)
        let id3 = try RFC_2822.Message.ID(ascii: "<other@example.com>".utf8)
        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("Successfully tests case-insensitive id-right")
    func testCaseInsensitiveIdRight() throws {
        let id1 = try RFC_2822.Message.ID(ascii: "<id@EXAMPLE.COM>".utf8)
        let id2 = try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8)
        #expect(id1 == id2)
    }

    @Test("Successfully tests hashable")
    func testHashable() throws {
        var set: Set<RFC_2822.Message.ID> = []
        set.insert(try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8))
        set.insert(try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8))
        set.insert(try RFC_2822.Message.ID(ascii: "<other@example.com>".utf8))
        #expect(set.count == 2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = try RFC_2822.Message.ID(ascii: "<id@example.com>".utf8)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Message.ID.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Successfully serializes to string")
    func testSerialization() throws {
        let id = try RFC_2822.Message.ID(ascii: "<unique-id@example.com>".utf8)
        #expect(String(id) == "<unique-id@example.com>")
    }
}

// MARK: - Timestamp Tests

@Suite("RFC 2822 Timestamp Tests")
struct TimestampTests {
    @Test("Timestamp creation")
    func testTimestampCreation() {
        let timestamp = RFC_2822.Timestamp(secondsSinceEpoch: 0.0)
        #expect(timestamp.secondsSinceEpoch == 0.0)
    }

    @Test("Timestamp equality")
    func testTimestampEquality() {
        let timestamp1 = RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)
        let timestamp2 = RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)
        let timestamp3 = RFC_2822.Timestamp(secondsSinceEpoch: 2000.0)

        #expect(timestamp1 == timestamp2)
        #expect(timestamp1 != timestamp3)
    }

    @Test("Timestamp hashable")
    func testTimestampHashable() {
        var set: Set<RFC_2822.Timestamp> = []

        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 1000.0))
        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)) // Duplicate
        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 2000.0))

        #expect(set.count == 2)
    }

    @Test("Successfully parses timestamp from bytes")
    func testTimestampParsing() throws {
        let timestamp = try RFC_2822.Timestamp(ascii: "1234567890".utf8)
        #expect(timestamp.secondsSinceEpoch == 1234567890.0)
    }

    @Test("Successfully parses timestamp with whitespace")
    func testTimestampWithWhitespace() throws {
        let timestamp = try RFC_2822.Timestamp(ascii: "  1234567890  ".utf8)
        #expect(timestamp.secondsSinceEpoch == 1234567890.0)
    }

    @Test("Fails with empty input")
    func testEmptyTimestamp() throws {
        #expect(throws: RFC_2822.Timestamp.Error.empty) {
            _ = try RFC_2822.Timestamp(ascii: "".utf8)
        }
    }

    @Test("Fails with invalid format")
    func testInvalidTimestamp() throws {
        #expect(throws: RFC_2822.Timestamp.Error.self) {
            _ = try RFC_2822.Timestamp(ascii: "not-a-number".utf8)
        }
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = RFC_2822.Timestamp(secondsSinceEpoch: 1234567890.0)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Timestamp.self, from: encoded)
        #expect(original == decoded)
    }
}

// MARK: - Fields Tests

@Suite("RFC 2822 Fields Tests")
struct FieldsTests {
    @Test("Successfully creates fields with required fields")
    func testFieldsCreation() {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "sender", domain: "example.com")
            )]
        )
        #expect(fields.from.count == 1)
        #expect(fields.originationDate.secondsSinceEpoch == 1234567890)
    }

    @Test("Successfully creates fields with optional fields")
    func testFieldsWithOptionalFields() {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: "Sender",
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "sender", domain: "example.com")
            )],
            messageID: RFC_2822.Message.ID(idLeft: "unique", idRight: "example.com"),
            subject: "Test Subject"
        )
        #expect(fields.subject == "Test Subject")
        #expect(fields.messageID?.idLeft == "unique")
    }

    @Test("Successfully parses fields from bytes")
    func testFieldsParsing() throws {
        let raw = "Date: 1234567890\r\nFrom: sender@example.com\r\nSubject: Test"
        let fields = try RFC_2822.Fields(ascii: raw.utf8)
        #expect(fields.subject == "Test")
        #expect(fields.from.count == 1)
    }

    @Test("Fails with empty input")
    func testEmptyFields() throws {
        #expect(throws: RFC_2822.Fields.Error.empty) {
            _ = try RFC_2822.Fields(ascii: "".utf8)
        }
    }

    @Test("Fails with missing Date field")
    func testMissingDateField() throws {
        let raw = "From: sender@example.com\r\n"
        #expect(throws: RFC_2822.Fields.Error.self) {
            _ = try RFC_2822.Fields(ascii: raw.utf8)
        }
    }

    @Test("Fails with missing From field")
    func testMissingFromField() throws {
        let raw = "Date: 1234567890\r\n"
        #expect(throws: RFC_2822.Fields.Error.self) {
            _ = try RFC_2822.Fields(ascii: raw.utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() {
        let f1 = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1000),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "a", domain: "b.com")
            )]
        )
        let f2 = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1000),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "a", domain: "b.com")
            )]
        )
        #expect(f1 == f2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "test", domain: "example.com")
            )],
            subject: "Test"
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Fields.self, from: encoded)
        #expect(original == decoded)
    }
}

// MARK: - Message Tests

@Suite("RFC 2822 Message Tests")
struct MessageTests {
    @Test("Successfully creates message with fields only")
    func testMessageFieldsOnly() {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "sender", domain: "example.com")
            )]
        )
        let message = RFC_2822.Message(fields: fields)
        #expect(message.body == nil)
    }

    @Test("Successfully creates message with body")
    func testMessageWithBody() {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "sender", domain: "example.com")
            )]
        )
        let message = RFC_2822.Message(fields: fields, body: "Hello, World!")
        #expect(message.body != nil)
    }

    @Test("Successfully parses message from bytes")
    func testMessageParsing() throws {
        let raw = "Date: 1234567890\r\nFrom: sender@example.com\r\nSubject: Test\r\n\r\nThis is the body."
        let message = try RFC_2822.Message(ascii: raw.utf8)
        #expect(message.fields.subject == "Test")
        #expect(message.body != nil)
    }

    @Test("Successfully parses message without body")
    func testMessageWithoutBody() throws {
        let raw = "Date: 1234567890\r\nFrom: sender@example.com"
        let message = try RFC_2822.Message(ascii: raw.utf8)
        #expect(message.body == nil)
    }

    @Test("Fails with empty input")
    func testEmptyMessage() throws {
        #expect(throws: RFC_2822.Message.Error.empty) {
            _ = try RFC_2822.Message(ascii: "".utf8)
        }
    }

    @Test("Successfully tests equality")
    func testEquality() {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1000),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "a", domain: "b.com")
            )]
        )
        let m1 = RFC_2822.Message(fields: fields, body: "test")
        let m2 = RFC_2822.Message(fields: fields, body: "test")
        #expect(m1 == m2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let fields = RFC_2822.Fields(
            originationDate: RFC_2822.Timestamp(secondsSinceEpoch: 1234567890),
            from: [RFC_2822.Mailbox(
                displayName: nil,
                emailAddress: RFC_2822.AddrSpec(__unchecked: (), localPart: "test", domain: "example.com")
            )]
        )
        let original = RFC_2822.Message(fields: fields)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Message.self, from: encoded)
        #expect(original.fields.originationDate == decoded.fields.originationDate)
        #expect(original.fields.from.count == decoded.fields.from.count)
        #expect(decoded.body == nil)
    }
}

// MARK: - Message.Body Tests

@Suite("RFC 2822 Message.Body Tests")
struct MessageBodyTests {
    @Test("Successfully creates body from string")
    func testBodyFromString() {
        let body = RFC_2822.Message.Body("Hello, World!")
        #expect(String(body) == "Hello, World!")
    }

    @Test("Successfully creates body from bytes")
    func testBodyFromBytes() {
        let bytes: [UInt8] = [72, 101, 108, 108, 111] // "Hello"
        let body = RFC_2822.Message.Body(bytes)
        #expect(body.bytes == bytes)
    }

    @Test("Successfully creates body using string literal")
    func testBodyStringLiteral() {
        let body: RFC_2822.Message.Body = "Test body"
        #expect(String(body) == "Test body")
    }

    @Test("Successfully parses body from ASCII bytes")
    func testBodyParsing() throws {
        let body = try RFC_2822.Message.Body(ascii: "Test content".utf8)
        #expect(String(body) == "Test content")
    }

    @Test("Successfully tests equality")
    func testEquality() {
        let b1 = RFC_2822.Message.Body("Hello")
        let b2 = RFC_2822.Message.Body("Hello")
        let b3 = RFC_2822.Message.Body("World")
        #expect(b1 == b2)
        #expect(b1 != b3)
    }

    @Test("Successfully tests hashable")
    func testHashable() {
        var set: Set<RFC_2822.Message.Body> = []
        set.insert(RFC_2822.Message.Body("Hello"))
        set.insert(RFC_2822.Message.Body("Hello"))
        set.insert(RFC_2822.Message.Body("World"))
        #expect(set.count == 2)
    }

    @Test("Successfully encodes and decodes")
    func testCodable() throws {
        let original = RFC_2822.Message.Body("Test body content")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_2822.Message.Body.self, from: encoded)
        #expect(original == decoded)
    }
}
