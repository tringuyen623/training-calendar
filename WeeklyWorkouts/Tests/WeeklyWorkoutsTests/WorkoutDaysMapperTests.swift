import Foundation
import Testing
@testable import WeeklyWorkouts

struct WorkoutDaysMapperTests {
    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsOnNon200HTTPResponse(statusCode: Int) {
        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(makeJSON(days: []), from: HTTPURLResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsOn200HTTPResponseWithInvalidJSON() {
        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(Data("invalid json".utf8), from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test(arguments: ["_id", "day", "assignments"])
    func map_throwsOn200HTTPResponseWithDayMissingField(field: String) {
        var day = makeDayJSON(workouts: [makeWorkoutJSON()])
        day[field] = nil

        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(makeJSON(days: [day]), from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test(arguments: ["_id", "title", "status", "total_exercise"])
    func map_throwsOn200HTTPResponseWithWorkoutMissingField(field: String) {
        var workout = makeWorkoutJSON()
        workout[field] = nil

        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(makeJSON(days: [makeDayJSON(workouts: [workout])]), from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test(arguments: [-1, 3])
    func map_throwsOn200HTTPResponseWithUnknownStatus(status: Int) {
        let day = makeDayJSON(workouts: [makeWorkoutJSON(status: status)])

        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(makeJSON(days: [day]), from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test(arguments: [-1, 7])
    func map_throwsOn200HTTPResponseWithDayOutOfRange(day: Int) {
        #expect(throws: (any Error).self) {
            try WorkoutDaysMapper.map(makeJSON(days: [makeDayJSON(day: day)]), from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test func map_deliversNoDaysOn200HTTPResponseWithEmptyJSONList() throws {
        let days = try WorkoutDaysMapper.map(makeJSON(days: []), from: HTTPURLResponse(statusCode: 200))

        #expect(days.isEmpty)
    }

    @Test func map_deliversMappedDaysOn200HTTPResponseWithJSONDays() throws {
        let json = makeJSON(days: [
            makeDayJSON(id: "day-3", day: 3, workouts: [
                makeWorkoutJSON(id: "w-completed", title: "Legs day", status: 2, exerciseCount: 5),
            ]),
            makeDayJSON(id: "day-0", day: 0, workouts: [
                makeWorkoutJSON(id: "w-assigned", title: "Full warm up workout", status: 0, exerciseCount: 6),
                makeWorkoutJSON(id: "w-missed", title: "HIIT Tabata 20:10 8x8", status: 1, exerciseCount: 15),
            ]),
            makeDayJSON(id: "day-5", day: 5, workouts: []),
        ])

        let days = try WorkoutDaysMapper.map(json, from: HTTPURLResponse(statusCode: 200))

        #expect(days == [
            WorkoutDay(id: "day-3", day: 3, workouts: [
                Workout(id: "w-completed", title: "Legs day", status: .completed, exerciseCount: 5),
            ]),
            WorkoutDay(id: "day-0", day: 0, workouts: [
                Workout(id: "w-assigned", title: "Full warm up workout", status: .assigned, exerciseCount: 6),
                Workout(id: "w-missed", title: "HIIT Tabata 20:10 8x8", status: .missed, exerciseCount: 15),
            ]),
            WorkoutDay(id: "day-5", day: 5, workouts: []),
        ])
    }
}
