# MindVault

MindVault is a privacy-first, offline SwiftUI journaling app built with a strict MVVM + dependency injection architecture. The app is designed around a calm, premium UX with local authentication, custom onboarding, a custom calendar, sticky notes, seeded demo content, and live theme customization.

## Highlights

- Offline-first: no external APIs or cloud dependency
- Privacy-first local authentication with passcode and optional biometrics
- SwiftUI app architecture using MVVM and dependency injection
- In-app theming with Light, Dark, and System modes
- Custom onboarding flow with multi-page animated experience
- Core Data-backed journal entries and sticky notes
- Custom month calendar with date indicators and journal creation from calendar
- Local notification reminders with configurable time
- Local reset flow that clears persistence, files, and stored preferences

## Features

### Onboarding and Authentication

- Premium multi-step onboarding flow
- Passcode creation as part of onboarding
- Optional Face ID / Touch ID enablement
- Lock screen for returning users
- Local reset path if passcode is forgotten

### Journal

- Create, edit, pin, and delete journal entries
- Date-based journal browsing
- Entry editor presented full-screen for a cleaner writing flow
- Seeded sample entries on first launch

### Sticky Notes

- Create quick sticky notes for the selected day
- Drag notes around the board
- Edit text and color
- Delete notes from the sticky editor

### Calendar

- Custom month grid, not `UIDatePicker`
- Select dates instantly
- Entry indicators for dates with saved journal content
- Double tap a date to open the journal editor for that day

### Settings

- Theme mode: `System`, `Light`, `Dark`
- Font scale customization
- Font style selection
- Controlled text color palette
- Reminder toggle and time selection
- Logout and full local data wipe

### Insights and Search

- Search across titles, body text, and tags
- Lightweight analytics for totals, streak, pinned entries, and top mood

## Architecture

MindVault follows a strict layered structure:

- `View`: SwiftUI screens and reusable UI components
- `ViewModel`: `@MainActor` observable types managing UI state
- `Model`: Core Data entities created programmatically
- `Services`: persistence, storage, security, theme, notifications, and calendar logic

The dependency graph is rooted in [`AppContainer.swift`](/Users/vedprakashmishra/Documents/MindVault/MindVault/App/AppContainer.swift), which bootstraps all services and injects them into the app session and feature view models.

### Core Services

- `PersistenceManager`
  Core Data stack, fetch APIs, save APIs, and full store reset
- `StorageManager`
  Clears Core Data, local files, and `UserDefaults`
- `SecurityManager`
  Local passcode management and biometric authentication
- `ThemeManager`
  Persists theme settings and exposes dynamic fonts/colors
- `NotificationManager`
  Configures local reminders with `UNUserNotificationCenter`
- `CalendarManager`
  Builds month grids and date comparison helpers

### App State

[`AppSession.swift`](/Users/vedprakashmishra/Documents/MindVault/MindVault/App/AppSession.swift) controls the root app phases:

- `launching`
- `onboarding`
- `locked`
- `unlocked`

It also owns shared session state such as:

- selected journal date
- active tab
- auth error messaging
- reminder refresh
- logout/reset flow

## Project Structure

```text
MindVault/
  App/
    AppContainer.swift
    AppRootView.swift
    AppSession.swift
  Core/
    Extensions/
    Persistence/
    Security/
    Storage/
  Features/
    Analytics/
    Calendar/
    Journal/
    Onboarding/
    Search/
    Settings/
    StickyNotes/
  Shared/
    Components/
    Theme/
```

## Persistence Model

The Core Data model is created in code and currently includes:

- `JournalEntryEntity`
  - id
  - title
  - bodyText
  - createdAt
  - updatedAt
  - mood
  - tagsRaw
  - colorHex
  - isPinned
- `StickyNoteEntity`
  - id
  - text
  - colorHex
  - createdAt
  - x
  - y
  - rotation
  - linkedDate
  - entryID

## First Launch Flow

1. App shows splash screen
2. App checks onboarding completion state
3. If needed, onboarding is shown
4. User creates a 4-digit MindVault passcode
5. App moves to lock screen
6. User unlocks into the main app

Seed data is loaded on first launch through `SeedDataProvider`.

## Reset Behavior

`StorageManager.clearAllData()` clears:

- Core Data stores
- app support files
- documents
- caches
- persisted defaults

This returns the app to onboarding and effectively wipes the local vault on device.

## Requirements

- Xcode 17+
- iOS SDK compatible with the current project settings
- macOS with simulator/device tooling available

## Build

Open the project in Xcode:

```bash
open MindVault.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project MindVault.xcodeproj -scheme MindVault -destination 'generic/platform=iOS' -derivedDataPath /tmp/MindVaultDerived CODE_SIGNING_ALLOWED=NO build
```

## Current Notes

- The app is intentionally local-only today.
- Authentication is app-level, not account-based.
- The UI theming system is active across the main app surfaces and onboarding/lock flow.
- The app uses seeded local content so the experience is populated on first run.

## Future Improvements

- Add unit tests for view models and services
- Add UI tests for onboarding, lock, settings, and journal CRUD flows
- Expand analytics depth
- Support richer tagging and filtering
- Add optional export/import flows

## License

This repository currently has no explicit license file.
