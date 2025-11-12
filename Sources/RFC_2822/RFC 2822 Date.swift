//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Foundation

public enum RFC_2822 {}

extension RFC_2822 {
    public enum Date {}
}

@available(macOS 12.0, *)
extension RFC_2822.Date {
    public static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if #available(macOS 13, *) {
            formatter.timeZone = .gmt
        } else {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return formatter
    }()

    /// Format a `Date` into RFC2822-compliant string
    static func string(from date: Foundation.Date) -> String {
        formatter.string(from: date)
    }

    /// Parse an RFC2822-compliant string into a `Foundation.Date`
    static func date(from string: String) -> Foundation.Date? {
        formatter.date(from: string)
    }
}

@available(macOS 12.0, *)
extension FormatStyle where Self == Foundation.Date.FormatStyle {
    public static var rfc2822: RFC2822DateStyle {
        RFC2822DateStyle()
    }
}

@available(macOS 12.0, *)
public struct RFC2822DateStyle: FormatStyle {
    public typealias FormatInput = Foundation.Date
    public typealias FormatOutput = String

    public func format(_ value: Foundation.Date) -> String {
        RFC_2822.Date.formatter.string(from: value)
    }
}
