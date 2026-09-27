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
  And the cache is empty
 When the customer opens the Training Calendar
 Then the app should display the latest workouts from remote
  And save them to the cache

Given the customer has connectivity
  And there's a cached version of the current week
 When the customer opens the Training Calendar
 Then the app should display the cached workouts
  And fetch the latest workouts from remote
  And replace the cache with the new workouts and display them
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
 Then the app should display the cached workouts

Given the customer doesn't have connectivity
  And the cache belongs to a previous week
 When the customer opens the Training Calendar
 Then the app should display the 7 empty day cells of the current week
  And display an error message

Given the customer doesn't have connectivity
  And the cache is empty
 When the customer opens the Training Calendar
 Then the app should display the 7 empty day cells of the current week
  And display an error message
```

### Narrative #3

```
As a customer
I want to see the status of each workout this week
So I know what I have done, what I missed and what is still ahead
```

#### Scenarios (Acceptance criteria)

```
Given a workout on a day before today
 When the customer views the week
 Then it should show Completed if completed, otherwise Missed

Given a workout today
 When the customer views the week
 Then it should show Completed if completed, otherwise Assigned

Given a workout on a day after today
 When the customer views the week
 Then it should show as upcoming, with no status
```

### Story: Customer marks a workout as completed

### Narrative #4

```
As a customer
I want to mark a workout as completed
So I can track what I have done this week
```

#### Scenarios (Acceptance criteria)

```
Given a workout that is not completed
 When the customer marks the workout as completed
 Then the workout should be shown as completed
  And it should stay completed after a refresh or when the app is reopened

Given a workout that is completed
 When the customer unmarks the workout
 Then the workout should no longer be shown as completed
  And its status should fall back to Missed (past), Assigned (today) or upcoming (future)
```

## Use Cases

### Load Workouts From Remote Use Case

#### Data:
- URL

#### Primary course (happy path):
1. Execute "Load Workouts" command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates weekly workouts from valid data.
5. System delivers weekly workouts.

#### Invalid data – error course (sad path):
1. System delivers invalid data error.

#### Request failure – error course (sad path):
1. System delivers request failure error.

#### Cancel course:
1. System delivers a cancellation error.

---

### Load Workouts From Cache Use Case

#### Primary course:
1. Execute "Load Workouts" command.
2. System retrieves workouts data from cache.
3. System validates the cache was saved in the current week (Mon–Sun).
4. System creates weekly workouts from cached data.
5. System delivers weekly workouts.

#### Retrieval error course (sad path):
1. System delivers error.

#### Cache from a previous week course (sad path):
1. System delivers no workouts.

#### Empty cache course (sad path):
1. System delivers no workouts.

---

### Validate Workouts Cache Use Case

#### Primary course:
1. Execute "Validate Cache" command.
2. System retrieves workouts data from cache.
3. System validates the cache was saved in the current week.

#### Retrieval error course (sad path):
1. System delivers error. Nothing is deleted: the next successful remote load replaces the cache.

#### Cache from a previous week course (sad path):
1. System deletes the completion marks, then the cached workouts.

---

### Cache Workouts Use Case

#### Data:
- Weekly workouts

#### Primary course (happy path):
1. Execute "Save Workouts" command with above data.
2. System deletes old cache data.
3. System encodes weekly workouts.
4. System timestamps the new cache.
5. System saves new cache data.
6. System delivers success message.

#### Deleting error course (sad path):
1. System delivers error.

#### Saving error course (sad path):
1. System delivers error.

---

### Toggle Workout Completion Use Case

#### Data:
- Workout ID
- Its current completion (the local mark if any, otherwise the server status)

#### Primary course (happy path):
1. Execute "Toggle Completion" command with above data.
2. System inverts the current completion.
3. System saves the inverted completion as the mark for the ID, replacing any previous mark.
4. System delivers the new completion.

#### Saving error course (sad path):
1. System keeps the previous mark.
2. System delivers error.

---

### Apply Completion Marks Use Case

#### Data:
- Weekly workouts
- Completion marks (by workout ID)

#### Primary course:
1. Execute "Apply Completion Marks" command with above data.
2. For each workout with a mark, System sets whether it's completed as the mark says, whatever the server status.
3. Workouts without a mark keep the server's completion.
4. System ignores marks for workouts that aren't in the week.
5. System delivers the weekly workouts.

## Flowchart

```mermaid
flowchart TD
    Open([Open the calendar]) --> Cache[Load workouts from cache]
    Cache --> HasCache{Valid cache?}
    HasCache -- yes --> ShowCache[Display cached workouts]
    HasCache -- no --> ShowEmpty[Display the empty week while loading]
    ShowCache --> Remote[Load workouts from remote]
    ShowEmpty --> Remote
    Remote --> Ok{Loaded?}
    Ok -- no, nothing shown --> Error[Display an error message]
    Ok -- no, cache shown --> Keep[Keep displaying the cache]
    Ok -- yes --> Save[Replace the cache] --> Notify[Cache notifies the change] --> Update[Display the new workouts]
```

## Model Specs

### Workout Day

| Property | Type |
| --- | --- |
| `id` | `String` |
| `day` | `Int` (0 = Monday … 6 = Sunday) |
| `workouts` | `[Workout]` |

### Workout

| Property | Type |
| --- | --- |
| `id` | `String` |
| `title` | `String` |
| `status` | `assigned` (0), `missed` (1) or `completed` (2) |
| `exerciseCount` | `Int` |

## Payload Contract

```
GET https://mock.internalef.com/workouts

200 RESPONSE

{
  "data": [
    {
      "_id": "68c0a1f45b9d4a0017c8e104",
      "day": 4,
      "assignments": [
        {
          "_id": "68c0a1f45b9d4a0017c8e204",
          "title": "Legs day",
          "status": 0,
          "total_exercise": 7
        },
        {
          "_id": "68c0a1f45b9d4a0017c8e205",
          "title": "HIIT Tabata 20:10 8x8",
          "status": 0,
          "total_exercise": 15
        }
      ]
    },
    {
      "_id": "68c0a1f45b9d4a0017c8e105",
      "day": 5,
      "assignments": []
    }
  ]
}
```

## Assumptions & Decisions

The brief and the mock API leave a few points open. These are the decisions taken and why.

| # | Open point | What I found | Decision |
| --- | --- | --- | --- |
| 1 | The brief lists two different endpoints | `https://mock.internalef.com/workouts` returns 200; `demo6732818.mockable.io/workouts` did not respond (checked Sep 26, 2026) | Use `mock.internalef.com`. Keep the base URL in configuration and ship a mock JSON file in the repo for tests and previews |
| 2 | Is `day` 0 Monday or Sunday? | The payload has no real dates, only an index 0...6 | `day 0 = Monday`, matching the Mon–Sun week view, mapped onto the real dates of the current week |
| 3 | What do `status` 0/1/2 mean? | Not documented | Assume `0 = assigned`, `1 = missed`, `2 = completed`. The displayed status is **derived** from the day relative to today plus the completion flag, not shown raw |
| 4 | Are local completion marks overwritten by a newer fetch? | Not specified | No. Marks are stored separately by workout ID and applied on top of remote data — a local mark wins |
| 5 | Can future workouts be toggled? | The brief says tapping any non-empty cell toggles it. The design only shows a completed past workout | Yes, any workout can be toggled. A completed workout uses the completed style whatever its day, including an upcoming one |
| 6 | Which timezone defines "this week" and "today"? | Not specified | The device's timezone and calendar, with the week always starting on Monday (independent of locale) |
| 7 | "Fetching updates (if any)": should the app use `ETag`? | The brief doesn't say. The server supports `ETag` (verified), but it isn't a documented contract | Not handled: this use case doesn't need it, as the response is a single small week of data, and there is no one to confirm otherwise. Every load fetches the full response, replaces the cache and displays it; when nothing changed the screen looks the same, so no comparison is needed |
| 8 | Remote fetch fails while cached data is shown | Not specified | Keep the cached data and show no error — it is still valid for this week, and the next launch or foreground refetches |
| 9 | When does the cache expire? | The payload only describes "the current week" (index 0...6, no dates) | The cache is valid while it was saved in the same Mon–Sun week as now. From the next Monday it expires: workouts and completion marks are deleted (so stale marks can't apply if the server reuses IDs). Validity is re-checked when the app returns to the foreground |
| 10 | What to show when loading fails and there is no valid cache | Neither the brief nor the design defines an error state | Show the empty week with a short error message. No extra error UI is invented; loading is retried on the next launch or when the app returns to the foreground |
| 11 | What is the API contract? | There is no API documentation, only the mock endpoint's response. In the observed response (7 days, 6 workouts) every field is present and non-null, `status` is 0, 1 or 2, and `day` is 0...6 | The Payload Contract above is inferred from that response, not agreed with a backend team. All its fields are treated as required, and only a `200` response is treated as success. Decoding is strict: a response that doesn't match — including an unknown `status` or a `day` outside 0...6 — is an invalid data error for the whole week |
| 12 | How are loading errors classified? | The brief doesn't require any specific error handling | Three categories only: any failure to get a response (no network, timeout, TLS failure, a non-HTTP response) is a request failure; a response that can't be used is invalid data; a cancelled load delivers a cancellation error. Finer categories would be added only if the app had to handle them differently |
| 13 | Which persistence layer? | The brief allows any persistence layer | SwiftData, as an implementation detail behind the cache store protocol. The store notifies when the cached data changes; how it detects that is up to the implementation, and the use cases don't depend on it |
| 14 | What does loading look like? | The loading frame shows the 7 dates with empty rows; the brief asks for "an empty/loading state" | Each day shows its date and a shimmering placeholder card, so it's clear data is on its way. This is a deliberate difference from the loading frame |
| 15 | How is a single exercise written? | The design only shows plural counts | "1 exercise", otherwise "N exercises" |
| 16 | What does the error state look like? | Not in the design | A short one-line message in the design's secondary text style |
| 17 | Should validation delete a cache it can't read? | Not specified | No. A read can fail temporarily, and deleting would lose a good cache; a truly corrupt cache is replaced by the next successful remote load |

## Architecture

```mermaid
graph TD
    App["TrainingCalendar app<br/>composition root"] --> UI["WeeklyWorkoutsUI<br/>SwiftUI views"]
    App --> Package
    UI --> Package
    subgraph Package["WeeklyWorkouts"]
        Remote["Remote workouts loader<br/>API"] -. conforms to .-> Loader["Workouts loader<br/>protocol"]
        Local["Local workouts loader<br/>cache"] -. conforms to .-> Loader
        Local --> Store["Workouts store<br/>protocol, notifies changes"]
        Loader --> Models["Weekly workouts<br/>models"]
    end
```

Solid arrows mean "depends on"; dotted arrows mean "conforms to". The internal structure of `WeeklyWorkouts` emerges through TDD; this diagram is updated as it does.
