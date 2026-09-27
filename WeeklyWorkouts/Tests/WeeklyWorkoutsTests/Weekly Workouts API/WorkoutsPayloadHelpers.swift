import Foundation

func makeJSON(days: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: ["data": days])
}

func makeDayJSON(id: String = "any-day-id", day: Int = 0, workouts: [[String: Any]] = []) -> [String: Any] {
    ["_id": id, "day": day, "assignments": workouts]
}

func makeWorkoutJSON(id: String = "any-workout-id", title: String = "any title", status: Int = 0, exerciseCount: Int = 1) -> [String: Any] {
    ["_id": id, "title": title, "status": status, "total_exercise": exerciseCount]
}
