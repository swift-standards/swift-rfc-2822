//
//  RFC_2822.AddrSpec.swift
//  swift-rfc-2822
//
//  RFC 2822 addr-spec (local-part@domain)
//

import INCITS_4_1986

extension RFC_2822 {
    /// Represents an addr-spec (local-part@domain)
    public struct AddrSpec: Hashable, Sendable, Codable {
        public let localPart: String
        public let domain: String

        public init(localPart: String, domain: String) throws(Error) {
            // Validate local-part and domain according to RFC 2822 3.4.1
            guard Self.validateLocalPart(localPart) else {
                throw Error.invalidLocalPart(localPart)
            }

            guard Self.validateDomain(domain) else {
                throw Error.invalidDomain(domain)
            }

            self.localPart = localPart
            self.domain = domain
        }

        private static func validateLocalPart(_ localPart: String) -> Bool {
            guard !localPart.isEmpty else { return false }

            // Per RFC 2822 3.4.1, local-part can be dot-atom or quoted-string
            if localPart.hasPrefix("\"") && localPart.hasSuffix("\"") {
                // Quoted string validation
                let quotedContent = String(localPart.dropFirst().dropLast())

                // Check for valid qtext or quoted-pair
                var isEscaped = false
                for char in quotedContent {
                    if isEscaped {
                        // After backslash, only allow certain chars to be escaped
                        guard char.isASCII && (char == "\\" || char == "\"" || char.isASCII) else {
                            return false
                        }
                        isEscaped = false
                    } else if char == "\\" {
                        isEscaped = true
                    } else {
                        // qtext = NO-WS-CTL / %d33-33 / %d35-91 / %d93-126
                        let isValidQText =
                            char.isASCII
                            && ((char.asciiValue! >= 1 && char.asciiValue! <= 8)
                                || (char.asciiValue! == 11 || char.asciiValue! == 12)
                                || (char.asciiValue! >= 14 && char.asciiValue! <= 31)
                                || char.asciiValue! == 33
                                || (char.asciiValue! >= 35 && char.asciiValue! <= 91)
                                || (char.asciiValue! >= 93 && char.asciiValue! <= 126))
                        guard isValidQText else { return false }
                    }
                }
                // Make sure we don't end with an unclosed escape
                return !isEscaped

            } else {
                // Dot-atom validation
                // Split into atoms by dots
                let atoms = localPart.split(separator: ".", omittingEmptySubsequences: false)

                // Check for empty atoms (consecutive dots or leading/trailing dots)
                guard !atoms.contains(where: { $0.isEmpty }) else { return false }

                // Validate each atom
                return atoms.allSatisfy { atom in
                    atom.allSatisfy { char in
                        // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
                        char.isASCIILetter || char.isASCIIDigit || "!#$%&'*+-/=?^_`{|}~".contains(char)
                    }
                }
            }
        }

        private static func validateDomain(_ domain: String) -> Bool {
            guard !domain.isEmpty else { return false }

            // Domain can be dot-atom or domain-literal
            if domain.hasPrefix("[") && domain.hasSuffix("]") {
                // Domain-literal validation
                let literalContent = String(domain.dropFirst().dropLast())

                var isEscaped = false
                for char in literalContent {
                    if isEscaped {
                        // After backslash, only certain chars can be escaped
                        guard char == "[" || char == "]" || char == "\\" else {
                            return false
                        }
                        isEscaped = false
                    } else if char == "\\" {
                        isEscaped = true
                    } else {
                        // dtext = NO-WS-CTL / %d33-90 / %d94-126
                        let isValidDText =
                            char.isASCII
                            && ((char.asciiValue! >= 1 && char.asciiValue! <= 8)
                                || (char.asciiValue! == 11 || char.asciiValue! == 12)
                                || (char.asciiValue! >= 14 && char.asciiValue! <= 31)
                                || (char.asciiValue! >= 33 && char.asciiValue! <= 90)
                                || (char.asciiValue! >= 94 && char.asciiValue! <= 126))
                        guard isValidDText else { return false }
                    }
                }
                // Make sure we don't end with an unclosed escape
                return !isEscaped

            } else {
                // Dot-atom validation
                // Split into atoms by dots
                let atoms = domain.split(separator: ".", omittingEmptySubsequences: false)

                // Check for empty atoms (consecutive dots or leading/trailing dots)
                guard !atoms.contains(where: { $0.isEmpty }) else { return false }

                // Must have at least one dot (at least two atoms)
                guard atoms.count >= 2 else { return false }

                // Validate each atom
                return atoms.allSatisfy { atom in
                    atom.allSatisfy { char in
                        // RFC 1035 restrictions for domain labels:
                        // - Start with letter
                        // - End with letter or digit
                        // - Interior chars can be letter, digit, or hyphen
                        if atom.first == char {
                            return char.isASCIILetter
                        } else if atom.last == char {
                            return char.isASCIILetter || char.isASCIIDigit
                        } else {
                            return char.isASCIILetter || char.isASCIIDigit || char == "-"
                        }
                    }
                }
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.AddrSpec: CustomStringConvertible {
    public var description: String {
        String(self)
    }
}
