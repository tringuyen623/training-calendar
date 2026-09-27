public protocol CompletionMarksStore {
    func deleteAllMarks() async throws

    /// Saves whether the workout is completed, replacing any previous mark for the ID in one step.
    /// If the insertion fails, the previous mark stays.
    func insertMark(_ isCompleted: Bool, for workoutID: String) async throws
}
