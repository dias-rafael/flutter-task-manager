# flutter-task-manager
A offline-first Task Manager APP using Flutter Bloc and Hive

### Requirements
- [Flutter](Version: 3.41.9) - https://docs.flutter.dev/install
- [Mockoon](Local API) - https://mockoon.com/tutorials/getting-started/ (only for simulate API)

## TODO — Mockoon Setup

To run the project with the fake API:

- install Mockoon
- import the environment file located at:

```txt
lib/utils/mock_api/task-manager.json

- start the Mockoon server
- ensure the API is running on: http://localhost:3001
**Android emulators may not be able to access localhost. Run the command in the terminal: adb reverse tcp:3001 tcp:3001**

# Architecture Decision Records (ADR)

## ADR-001 — Persistence Engine Choice

### Context
The application requires:

- offline-first behavior
- fast local reads
- optimistic updates
- persistent sync queue
- lightweight setup
- deterministic testing

### Decision
Hive was selected as the local persistence engine.

### Rationale
Hive provides:

- simple key-value persistence
- fast startup/read performance
- lightweight integration
- easy object serialization
- no native database dependencies
- good fit for sync queue storage

The application stores:

- cached tasks
- pending sync operations

using separate Hive boxes.

### Tradeoffs
Pros:

- simple setup
- fast local access
- low boilerplate
- suitable for offline-first architecture

Cons:

- limited querying capabilities
- manual relationship management
- less powerful than relational/object databases

### Alternatives Considered
#### Isar

Pros:
- better querying
- indexes
- reactive queries

Cons:
- heavier setup for challenge scope
- additional complexity not necessary for current requirements

#### SQLite / Drift
Pros:
- relational modeling
- advanced querying

Cons:
- more boilerplate
- unnecessary complexity for current domain size

---

## ADR-002 — Conflict Resolution Strategy

### Context
The app supports optimistic offline mutations while remote updates may occur concurrently.
This creates potential synchronization conflicts.

### Decision
A server-wins strategy was implemented.

### Rationale
When a conflict occurs:

1. the failed operation is removed from the queue
2. the latest server task is fetched
3. local optimistic state is rolled back
4. UI is notified via Snackbar

This approach prioritizes:

- consistency
- predictable reconciliation
- simpler conflict semantics

### Tradeoffs
Pros:

- deterministic resolution
- simpler reasoning
- easier debugging
- reduced merge complexity

Cons:

- local user changes may be lost
- no field-level merging

---

## ADR-003 — Event Transformer Choices

### Context
The app processes concurrent user interactions including:

- rapid status toggles
- search input
- queue synchronization

Concurrency behavior must remain predictable.

### Decision
Different Bloc event transformers were selected depending on event semantics.

### Rationale
#### Sequential processing

Used for task status updates.

Reason:
- preserves mutation ordering
- prevents race conditions
- guarantees deterministic sync order

#### Restartable processing
Used for search.

Reason:
- only latest search matters
- previous searches should be cancelled
- improves responsiveness

### Tradeoffs
Pros:

- predictable concurrency
- avoids stale state
- improved UX

Cons:

- slightly more complex event orchestration
- requires careful testing

### Testing
Ordering and debounce behaviors are covered by unit tests.

---

## What I'd Do With Another 2 Days
Given additional time, I would focus on the following improvements:

### 1. Background Sync Improvements
- connectivity-aware sync scheduling

### 2. Expanded Test Coverage
- integration tests
- widget tests

### 3. Observability
- structured logging

### 4. Performance Improvements
- pagination improvements

### 5. Production Hardening
- authentication/token refresh handling

### 6. UI
- better feedback messages
- apply theme (colors, styles...)

### 7. Other deprioritized improvements
- app icon
- splash screen
- navigation (routes)
- localization