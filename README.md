# TabSaver

An iOS app for saving and managing browser tabs via a share extension. Tabs are stored on a self-hosted backend API, making it easy to capture URLs from Safari or any other app and access them later.

## Features

- Save URLs with titles and tags directly from the iOS share sheet
- Browse and search all saved tabs
- Open saved tabs in Safari or copy URLs to clipboard
- Tag-based organization with custom tag creation
- Configurable backend API URL (designed for NAS/home server hosting)

## Architecture

The project contains two targets:

- **TabSaver** — Main iOS app (SwiftUI). Displays saved tabs, supports search, detail view, and settings.
- **TabManagerShare** — iOS Share Extension (UIKit). Activated from the iOS share sheet to save URLs directly from Safari or other apps.

Both targets share data via an App Group (`group.com.usmakestwo.TabSaver`), which is used to store the backend API URL in shared `UserDefaults`.

### Stack

- Swift / SwiftUI (main app)
- Swift / UIKit (share extension)
- URLSession for networking (no third-party dependencies)
- MVVM with `ObservableObject` / `@Published`

## Backend API

TabSaver connects to a self-hosted REST API. Configure the base URL in the **Settings** tab (defaults to `http://192.168.1.100:5000`).

### Expected Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/tabs` | List all saved tabs |
| `POST` | `/api/tabs` | Create a new tab |
| `GET` | `/api/tabs/:id` | Get a tab by ID |
| `DELETE` | `/api/tabs/:id` | Delete a tab |
| `POST` | `/api/tabs/:id/tags` | Add a tag to a tab |
| `GET` | `/api/tags` | List all tags |
| `GET` | `/api/search?q=` | Search tabs |
| `GET` | `/api/health` | Health check |

### Tab Model

```json
{
  "id": 1,
  "url": "https://example.com",
  "title": "Example",
  "notes": "Optional note",
  "savedAt": "2025-01-01T00:00:00Z",
  "tags": ["reading", "dev"]
}
```

## Setup

1. Open `TabSaver.xcodeproj` in Xcode.
2. Set your development team in the project's Signing & Capabilities settings for both the `TabSaver` and `TabManagerShare` targets.
3. Ensure the App Group identifier matches in both target entitlements (`group.com.usmakestwo.TabSaver`).
4. Build and run on a device or simulator (iOS 15+).
5. In the **Settings** tab, update the API URL to point to your backend server.

## Usage

**Saving a tab from Safari:**
1. Tap the share button in Safari.
2. Select **TabSaver** from the share sheet.
3. Optionally add or select tags.
4. Tap **Save**.

**Browsing tabs:**
- Open the TabSaver app to see all saved tabs.
- Use the search bar to filter by title, URL, or tags.
- Tap a tab to view details, copy the URL, or open it in Safari.
- Swipe left on a tab to delete it.
