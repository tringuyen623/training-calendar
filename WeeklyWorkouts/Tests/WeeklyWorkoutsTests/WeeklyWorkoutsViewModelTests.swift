import Foundation
import Testing
import WeeklyWorkouts

@MainActor
struct WeeklyWorkoutsViewModelTests {
    @Test func init_doesNotRequestLoadOrToggle() {
        let (_, loader, toggler) = makeSUT()

        #expect(loader.loadCallCount == 0)
        #expect(toggler.receivedToggles.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: WeeklyWorkoutsViewModel, loader: WeekLoaderSpy, toggler: CompletionTogglerSpy) {
        let loader = WeekLoaderSpy()
        let toggler = CompletionTogglerSpy()
        let sut = WeeklyWorkoutsViewModel(
            loadWeek: loader.load,
            toggleCompletion: toggler.toggle
        )
        return (sut, loader, toggler)
    }
}

@MainActor
private final class WeekLoaderSpy {
    private(set) var loadCallCount = 0

    func load() async throws -> [WorkoutDay] {
        loadCallCount += 1
        return []
    }
}

@MainActor
private final class CompletionTogglerSpy {
    struct Toggle: Equatable {
        let workoutID: String
        let isCompleted: Bool
    }

    private(set) var receivedToggles: [Toggle] = []

    func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        receivedToggles.append(Toggle(workoutID: workoutID, isCompleted: isCompleted))
        return !isCompleted
    }
}
