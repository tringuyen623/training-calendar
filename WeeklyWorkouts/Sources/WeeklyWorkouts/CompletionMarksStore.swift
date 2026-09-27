public protocol CompletionMarksStore {
    func deleteAllMarks() async throws

    /// Saves whether the workout is completed, replacing any previous mark for the ID in one step.
    /// If the insertion fails, the previous mark stays.
    func insertMark(_ isCompleted: Bool, for workoutID: String) async throws

    /// Returns whether each marked workout is completed, keyed by workout ID. Empty when there are no marks.
    func retrieveAllMarks() async throws -> [String: Bool]
}
