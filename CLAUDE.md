# CLAUDE.md

Weekly training calendar for iOS (take-home test). SwiftUI, Swift Concurrency, iOS 17+.

## Source of truth

`README.md` — Feature Specs (BDD), Use Cases and Assumptions & Decisions define the behavior.
Don't add behavior that isn't there. If something is unclear or conflicts, stop and ask.

## Structure

- `WeeklyWorkouts/` — Swift package for the feature (iOS 17, macOS 14)
  - `WeeklyWorkouts` target — models, API, cache, rules, ViewModel. Imports Foundation and Observation only — never SwiftUI or UIKit.
  - `WeeklyWorkoutsUI` target — SwiftUI views. Must still compile for macOS.
- `TrainingCalendar/` — the iOS app. It is the composition root: the only place that creates concrete types and wires them together.

## Architecture rules

- Keep rules, networking, storage and UI separate. Data crosses boundaries as plain models.
- The logic doesn't depend on networking or storage: it defines the protocols it needs (HTTP client, stores) and those layers implement them.
- Business rules live below the ViewModel — never in views, ViewModels or stores: the current Mon–Sun week, a workout's status (missed / assigned / completed / upcoming), cache validity (only within the current week), and local completion marks overriding server status.
- Inject dependencies through initializers. No singletons.
- Treat time as a dependency: inject the current date and the calendar (with its time zone), so week boundaries are testable. Never use `Date()` or `Calendar.current` inside logic.
- Don't add a layer or protocol unless it removes real coupling.
- Loading the week is a stream: cached week first, then remote, emitting again only when the data changed. Every load calls the server; `URLSession`'s cache behavior is configured in the composition root, not hard-coded in the HTTP client.

## Presentation

- MVVM with a thin `@Observable` ViewModel: `send(_:)` with actions named by intent (`loadWeek`, `toggle(workoutID:)`), never by UI gesture or lifecycle.
- The ViewModel only formats for display: weekday "Mon", day "24", "5 exercises". It doesn't decide dates or status — it passes on the status and `isToday` from the rules.
- No `Color` or other UI-framework types in the ViewModel — the view maps status to colors.
- One container view owns the ViewModel. Other views take plain view data and closures, so they preview with sample data.

## Workflow

- Work one use case at a time. Before coding, list its tests (one per course) and wait for approval.
- Strict TDD: red → green → refactor, one test at a time. Use Swift Testing.
- Commit after each green and each refactor, one change per commit, with an imperative message stating what changed and why.
- For non-trivial generated logic (date math, merge, diff), add: `// Generated with Claude. Adjusted to handle <edge case>.`
- Files start flat; group into capability folders as they grow. No `Domain/`, `Core/` or `Utils/` folders.

## Commands

```sh
cd WeeklyWorkouts && swift test
```
