//
//  RFC_2822.AddrSpec.Error.swift
//  swift-rfc-2822
//
//  Addr-spec validation errors
//

extension RFC_2822.AddrSpec {
    /// Errors that can occur during addr-spec validation
    ///
    /// RFC 2822 Section 3.4.1 defines addr-spec as local-part@domain
    public enum Error: Swift.Error, Equatable {
        /// Local-part validation failed
        case invalidLocalPart(_ localPart: String)

        /// Domain validation failed
        case invalidDomain(_ domain: String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_2822.AddrSpec.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidLocalPart(let localPart):
            return "Invalid local-part '\(localPart)': must be dot-atom or quoted-string per RFC 2822"
        case .invalidDomain(let domain):
            return "Invalid domain '\(domain)': must be dot-atom or domain-literal per RFC 2822"
        }
    }
}
