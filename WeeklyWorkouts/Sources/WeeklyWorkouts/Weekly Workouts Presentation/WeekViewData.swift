/// What the week shows: its seven days, known even while loading or after a failure.
public struct WeekViewData: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case loading
        case loaded
        case failed(message: String)
    }

    public let days: [DayViewData]
    public let state: State

    public init(days: [DayViewData], state: State) {
        self.days = days
        self.state = state
    }
}
