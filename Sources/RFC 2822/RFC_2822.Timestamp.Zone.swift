extension RFC_2822.Timestamp {

    public enum Zone: Sendable, Codable, Hashable {
        case offset(minutes: Int)
        case unknown
    }
}
