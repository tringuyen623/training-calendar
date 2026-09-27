import Foundation
import SwiftData
import WeeklyWorkouts

/// Creates the week screen's objects and delivers the cached week to the ViewModel whenever the store changes.
final class WeeklyWorkoutsComposer {
    let viewModel: WeeklyWorkoutsViewModel
    private let service: WeeklyWorkoutsService

    init() {
        let calendar = Calendar.current
        let store = SwiftDataWorkoutsStore(modelContainer: Self.makeContainer())
        let service = WeeklyWorkoutsService(
            url: Self.workoutsURL,
            client: URLSessionHTTPClient(session: Self.makeSession()),
            store: store,
            calendar: calendar,
            currentDate: Date.init
        )

        self.service = service
        self.viewModel = WeeklyWorkoutsViewModel(
            service: service,
            calendar: calendar,
            now: Date.init
        )

        Task { [weak self] in
            for await _ in await store.changes() {
                await self?.displayCachedWeek()
            }
        }
    }

    func validateCache() async {
        try? await service.validateCache()
    }

    /// Loads the week again when there's no cached week for the current week, such as after the cache
    /// expired in a new week; with a current cached week nothing reloads, so the API isn't called.
    func loadWeekIfNeeded() async {
        guard await service.needsLoading() else { return }
        await viewModel.send(.loadWeek)
    }

    private func displayCachedWeek() async {
        guard let week = try? await service.loadCachedWeek() else { return }
        viewModel.display(week)
    }

    private static let workoutsURL = URL(string: "https://mock.internalef.com/workouts")!

    /// Every load asks the server: a cached response would hide the latest workouts.
    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Schema(SwiftDataWorkoutsStore.models))
        } catch {
            fatalError("Couldn't create the workouts store: \(error)")
        }
    }
}
