//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Testing

@testable import RFC_2822

@Suite
struct `RFC2822 Timestamp Tests` {

    @Test
    func `Timestamp creation`() {
        let timestamp = RFC_2822.Timestamp(secondsSinceEpoch: 0.0)

        #expect(timestamp.secondsSinceEpoch == 0.0)
    }

    @Test
    func `Timestamp equality`() {
        let timestamp1 = RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)
        let timestamp2 = RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)
        let timestamp3 = RFC_2822.Timestamp(secondsSinceEpoch: 2000.0)

        #expect(timestamp1 == timestamp2)
        #expect(timestamp1 != timestamp3)
    }

    @Test
    func `Timestamp hashable`() {
        var set: Set<RFC_2822.Timestamp> = []

        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 1000.0))
        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 1000.0)) // Duplicate
        set.insert(RFC_2822.Timestamp(secondsSinceEpoch: 2000.0))

        #expect(set.count == 2)
    }
}
