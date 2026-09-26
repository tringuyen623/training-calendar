# Training Calendar

A weekly training calendar for iOS: it shows the current week's workouts (Monday to Sunday) with their status, and lets the user mark workouts as completed locally. Data comes from a mock API and is cached so the app opens instantly with the last known week.

## Feature Specs

### Story: Customer requests to see this week's workouts

### Narrative #1

```
As an online customer
I want the app to automatically load my latest weekly workouts
So I can always see what I need to train this week
```

#### Scenarios (Acceptance criteria)

```
Given the customer has connectivity
  And there's a cached version of the current week
 When the customer opens the Training Calendar
 Then the app should display the cached workouts
  And fetch the latest workouts from remote
  And update the displayed workouts when remote data differs
  And replace the cache with the new workouts

Given the customer has connectivity
  And the cache is empty
 When the customer opens the Training Calendar
 Then the app should display the latest workouts from remote
  And save them to the cache

Given the customer has connectivity
  And there's a cached version of the current week
  And the remote data has not changed (HTTP 304)
 When the customer opens the Training Calendar
 Then the app should keep displaying the cached workouts
```

### Narrative #2

```
As an offline customer
I want the app to show the latest saved version of my weekly workouts
So I can still see my plan without a connection
```

#### Scenarios (Acceptance criteria)

```
Given the customer doesn't have connectivity
  And there's a cached version of the workouts
  And the cache belongs to the current week
 When the customer opens the Training Calendar
 Then the app should display the cached workouts with local completion marks

Given the customer doesn't have connectivity
  And the cache belongs to a previous week
 When the customer opens the Training Calendar
 Then the app should display the 7 empty day cells of the current week
  And show an error message with a retry action

Given the customer doesn't have connectivity
  And the cache is empty
 When the customer opens the Training Calendar
 Then the app should display the 7 empty day cells of the current week
  And show an error message with a retry action
```

### Story: Customer marks a workout as completed

### Narrative #3

```
As a customer
I want to mark a workout as completed by tapping it
So I can track what I have done this week
```

#### Scenarios (Acceptance criteria)

```
Given a workout that is not completed
 When the customer taps the workout
 Then the workout should be marked as completed
  And a checkmark should appear on the right side of the workout
  And the status label and colors should update to Completed
  And the mark should be persisted locally by workout ID

Given a workout that is completed
 When the customer taps the workout
 Then the completion mark should be removed
  And the status should fall back to Missed (past) / Assigned (today) / greyed (future)

Given the customer has marked workouts locally
 When a newer version of the workouts arrives from remote
 Then the local marks should still be applied to workouts with the same ID

Given the customer taps an empty day cell
 Then nothing should happen
```

### Story: Workout status depends on the day

```
Given a workout on a day before today
 Then it should show Completed if completed, otherwise Missed

Given a workout on today
 Then it should show Completed if completed, otherwise Assigned
  And today's date should be highlighted in purple

Given a workout on a day after today
 Then it should be greyed out with no status text

Given a workout name longer than the available width
 Then it should be truncated with "..." on a single line
```

## Assumptions & Decisions

The brief and the mock API leave a few points open. These are the decisions taken and why.

| # | Open point | What I found | Decision |
| --- | --- | --- | --- |
| 1 | The brief lists two different endpoints | `https://mock.internalef.com/workouts` returns 200; `demo6732818.mockable.io/workouts` did not respond (checked Sep 26, 2026) | Use `mock.internalef.com`. Keep the base URL in configuration and ship a mock JSON file in the repo for tests and previews |
| 2 | Is `day` 0 Monday or Sunday? | The payload has no real dates, only an index 0...6 | `day 0 = Monday`, matching the Mon–Sun week view, mapped onto the real dates of the current week |
| 3 | What do `status` 0/1/2 mean? | Not documented | Assume `0 = assigned`, `1 = missed`, `2 = completed`. The displayed status is **derived** from the day relative to today plus the completion flag, not shown raw |
| 4 | Are local completion marks overwritten by a newer fetch? | Not specified | No. Marks are stored separately by workout ID and applied on top of remote data — a local mark wins |
| 5 | Can future workouts be toggled? | The brief says tapping any non-empty cell toggles it | Yes, any workout can be toggled. A completed future workout shows the checkmark but keeps the greyed-out style |
| 6 | Which timezone defines "this week" and "today"? | Not specified | The device's timezone and calendar, with the week always starting on Monday (independent of locale) |
| 7 | How to "fetch updates (if any)" | The server returns `ETag` and `Last-Modified` headers | Send `If-None-Match`; on HTTP 304 keep the cache and skip re-rendering |
| 8 | Remote fetch fails while cached data is shown | Not specified | Keep the cached data and show no error — it is still valid for this week, and the next launch or foreground refetches. With no cache, show an error state with a retry action |
| 9 | When does the cache expire? | The payload only describes "the current week" (index 0...6, no dates) | The cache is valid while it was saved in the same Mon–Sun week as now. From the next Monday it expires: workouts, ETag and completion marks are deleted (so stale marks can't apply if the server reuses IDs). Validity is re-checked when the app returns to the foreground |
