public protocol WorkoutsLoader {
    func load() async throws -> [WorkoutDay]
}
