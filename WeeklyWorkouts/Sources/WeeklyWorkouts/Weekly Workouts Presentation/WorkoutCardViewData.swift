/// What a workout card shows, ready for display: no colors and no domain types.
public struct WorkoutCardViewData: Identifiable, Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case missed
        case assigned
        case completed
        case upcoming
    }

    public let id: String
    public let title: String
    /// "Missed", "Completed", or `nil` when the card shows no status word (assigned, upcoming).
    public let statusText: String?
    /// "1 exercise", "5 exercises".
    public let exerciseCount: String
    public let status: Status

    public init(id: String, title: String, statusText: String?, exerciseCount: String, status: Status) {
        self.id = id
        self.title = title
        self.statusText = statusText
        self.exerciseCount = exerciseCount
        self.status = status
    }
}
