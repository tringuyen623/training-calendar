import Foundation

enum WorkoutDaysMapper {
    private struct Root: Decodable {
        let data: [RemoteWorkoutDay]
    }

    private struct RemoteWorkoutDay: Decodable {
        let id: String
        let day: Int
        let assignments: [RemoteWorkout]

        private enum CodingKeys: String, CodingKey {
            case id = "_id"
            case day
            case assignments
        }

        func toModel() throws -> WorkoutDay {
            guard (0...6).contains(day) else {
                throw InvalidData()
            }
            return WorkoutDay(id: id, day: day, workouts: try assignments.map { try $0.toModel() })
        }
    }

    private struct RemoteWorkout: Decodable {
        let id: String
        let title: String
        let status: Int
        let exerciseCount: Int

        private enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title
            case status
            case exerciseCount = "total_exercise"
        }

        func toModel() throws -> Workout {
            Workout(id: id, title: title, status: try mappedStatus(), exerciseCount: exerciseCount)
        }

        private func mappedStatus() throws -> Workout.Status {
            switch status {
            case 0: return .assigned
            case 1: return .missed
            case 2: return .completed
            default: throw InvalidData()
            }
        }
    }

    struct InvalidData: Error {}

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [WorkoutDay] {
        guard response.statusCode == 200 else {
            throw InvalidData()
        }
        return try JSONDecoder().decode(Root.self, from: data).data.map { try $0.toModel() }
    }
}
