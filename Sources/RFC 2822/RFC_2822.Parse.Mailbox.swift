//
//  RFC_2822.Parse.Mailbox.swift
//  swift-rfc-2822
//
//  RFC 2822 mailbox: [display-name] "<" addr-spec ">" / addr-spec
//

public import Parser_Primitives

extension RFC_2822.Parse {
    /// Parses an RFC 2822 mailbox.
    ///
    /// `mailbox = name-addr / addr-spec`
    /// `name-addr = [display-name] angle-addr`
    /// `angle-addr = "<" addr-spec ">"`
    ///
    /// Returns the display name (if present) and addr-spec components.
    public struct Mailbox<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2822.Parse.Mailbox {
    public struct Output: Sendable {
        public let displayName: Input?
        public let localPart: Input
        public let domain: Input

        @inlinable
        public init(displayName: Input?, localPart: Input, domain: Input) {
            self.displayName = displayName
            self.localPart = localPart
            self.domain = domain
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
        case missingAtSign
        case unterminatedAngleBracket
        case emptyLocalPart
        case emptyDomain
    }
}

extension RFC_2822.Parse.Mailbox: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = RFC_2822.Parse.Mailbox<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard input.startIndex < input.endIndex else { throw .empty }

        // Scan for '<' to detect name-addr format
        var openAngle: Input.Index? = nil
        var idx = input.startIndex
        while idx < input.endIndex {
            if input[idx] == 0x3C {  // <
                openAngle = idx
                break
            }
            input.formIndex(after: &idx)
        }

        if let open = openAngle {
            // name-addr format
            let displayName: Input?
            if open > input.startIndex {
                displayName = input[input.startIndex..<open]
            } else {
                displayName = nil
            }

            let afterOpen = input.index(after: open)

            // Find '>' closing bracket
            var close: Input.Index? = nil
            var scanIdx = afterOpen
            while scanIdx < input.endIndex {
                if input[scanIdx] == 0x3E {  // >
                    close = scanIdx
                    break
                }
                input.formIndex(after: &scanIdx)
            }
            guard let closeIdx = close else { throw .unterminatedAngleBracket }

            // Split addr-spec inside angle brackets at last '@'
            let addrSlice = input[afterOpen..<closeIdx]
            var atIndex: Input.Index? = nil
            var atScan = addrSlice.startIndex
            while atScan < addrSlice.endIndex {
                if addrSlice[atScan] == 0x40 {  // @
                    atIndex = atScan
                }
                addrSlice.formIndex(after: &atScan)
            }

            guard let at = atIndex else { throw .missingAtSign }
            guard at > addrSlice.startIndex else { throw .emptyLocalPart }
            let afterAt = addrSlice.index(after: at)
            guard afterAt < addrSlice.endIndex else { throw .emptyDomain }

            let localPart = addrSlice[addrSlice.startIndex..<at]
            let domain = addrSlice[afterAt..<addrSlice.endIndex]

            input = input[input.index(after: closeIdx)...]
            return Output(displayName: displayName, localPart: localPart, domain: domain)
        } else {
            // Bare addr-spec format — find last '@'
            var atIndex: Input.Index? = nil
            var endIdx = input.startIndex
            while endIdx < input.endIndex {
                let byte = input[endIdx]
                if byte == 0x40 { atIndex = endIdx }
                // Stop at whitespace or comma
                if byte == 0x2C || byte == 0x0D || byte == 0x0A { break }
                input.formIndex(after: &endIdx)
            }

            guard let at = atIndex else { throw .missingAtSign }
            guard at > input.startIndex else { throw .emptyLocalPart }
            let afterAt = input.index(after: at)
            guard afterAt < endIdx else { throw .emptyDomain }

            let localPart = input[input.startIndex..<at]
            let domain = input[afterAt..<endIdx]

            input = input[endIdx...]
            return Output(displayName: nil, localPart: localPart, domain: domain)
        }
    }
}
