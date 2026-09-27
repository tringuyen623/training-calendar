import Foundation

enum WorkoutDaysMapper {
    private struct Root: Decodable {
        let data: [RemoteWorkoutDay]
    }

    private struct RemoteWorkoutDay: Decodable {
        let _id: String
        let day: Int
        let assignments: [RemoteWorkout]
    }

    private struct RemoteWorkout: Decodable {
        let _id: String
        let title: String
        let status: Int
        let total_exercise: Int
    }

    struct InvalidData: Error {}

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [WorkoutDay] {
        guard response.statusCode == 200 else {
            throw InvalidData()
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        let statuses = root.data.flatMap(\.assignments).map(\.status)
        guard statuses.allSatisfy((0...2).contains) else {
            throw InvalidData()
        }
        return []
    }
}
