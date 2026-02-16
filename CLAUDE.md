# CLAUDE.md

This file provides context and conventions for AI-assisted development on TabSaver.

## Project Overview

TabSaver is a two-target iOS project:
- **TabSaver** — SwiftUI main app for browsing and managing saved tabs.
- **TabManagerShare** — UIKit share extension for capturing URLs from the iOS share sheet.

Both targets communicate with a self-hosted REST API and share configuration via an App Group.

## Key Files

| File | Purpose |
|------|---------|
| `TabSaver/Models.swift` | Data models (`Tab`, `TagResponse`) and `TabManagerViewModel` |
| `TabSaver/ContentView.swift` | Root tab view, tab list, search bar |
| `TabSaver/SettingsView.swift` | API URL configuration UI |
| `TabSaver/TabSaverApp.swift` | App entry point |
| `TabManagerShare/ShareViewController.swift` | Share extension: URL extraction, tag selection, API POST |

## Architecture & Patterns

- **MVVM**: `TabManagerViewModel` (in `Models.swift`) is the single source of truth for the main app. It owns all API calls and publishes state to SwiftUI views.
- **Async networking**: All API calls use `URLSession` with `async/await`. No third-party networking libraries.
- **App Group shared storage**: The API base URL is read/written via `UserDefaults(suiteName: "group.com.usmakestwo.TabSaver")`. Both targets must use this suite name to access shared config.
- **Debounced search**: Search triggers a 0.3s debounce on the `searchQuery` publisher before firing the API call.

## App Group & Entitlements

Both targets have an entitlement for `group.com.usmakestwo.TabSaver`. If you add a new target or rename the bundle, update the entitlements files and `UserDefaults` suite name in both `Models.swift` and `ShareViewController.swift`.

## API Integration

The base URL defaults to `http://192.168.1.100:5000` and is stored under the key `TabManagerAPIURL` in the shared `UserDefaults`. All endpoints are relative to this base URL. Local networking is enabled via `NSAllowsLocalNetworking` in the share extension's `Info.plist`.

When adding new API endpoints:
1. Add the method to `TabManagerViewModel` in `Models.swift`.
2. Follow the existing pattern: build a `URLRequest`, use `URLSession.shared.data(for:)`, decode the response.
3. Errors are surfaced via the `statusMessage: String` published property.

## UI Conventions

- **Main app**: Pure SwiftUI. Use `@StateObject` / `@ObservedObject` for the view model.
- **Share extension**: UIKit (`UIViewController` subclass). Tag chips are built programmatically using `UIButton` wrapped in a scroll view.
- Avoid mixing SwiftUI into the share extension unless adopting a `UIHostingController`.

## What to Avoid

- Do not add third-party dependencies without strong justification — the project intentionally uses only native frameworks.
- Do not hardcode the API base URL anywhere other than the default value in `Models.swift`. Always read from shared `UserDefaults`.
- The share extension has strict memory and lifecycle constraints. Keep it lightweight and avoid long-running background tasks beyond the single save operation.

## Common Tasks

**Add a new field to the Tab model:**
1. Update the `Tab` struct in `Models.swift`.
2. Verify `CodingKeys` if the JSON key differs from the Swift property name.
3. Update any UI in `ContentView.swift` that displays tab details.

**Add a new tag action in the share extension:**
- Tag fetching and saving logic lives entirely in `TabManagerShare/ShareViewController.swift`.

**Change the App Group identifier:**
- Update `TabSaver/TabSaver.entitlements`
- Update `TabManagerShare/TabManagerShare.entitlements`
- Update the suite name string in `Models.swift` and `ShareViewController.swift`
- Re-provision both App IDs in the Apple Developer portal with the new group.
