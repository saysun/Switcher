# Switcher Architecture

A lightweight menu-bar utility for naming and switching between macOS Spaces (desktops).

---

## Overview

```
┌─────────────────────────────────────────────────────┐
│                    main.swift                        │
│         NSApplication.shared.run()                   │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                   AppDelegate                        │
│  • Prompts for Accessibility permission             │
│  • Creates StatusBarManager                          │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│StatusBarManager│ │HotKeyManager│ │SpaceManager │
│ (Menu Bar UI) │ │(Global Shortcut)│(CGS API) │
└─────────────┘ └─────────────┘ └─────────────┘
          │            │            │
          ▼            ▼            ▼
┌─────────────────────────────────────────────────────┐
│   ConfigStore      SpaceNameStore                   │
│   (shortcuts.json) (spaces.json)                     │
└─────────────────────────────────────────────────────┘
```

---

## How It Works

### 1. Menu Bar Icon

The app lives in the menu bar (no Dock icon). The button shows the current desktop's custom name:

```
┌────────────────┐
│ ◆ Work        │  ← Menu bar showing custom name "Work"
└────────────────┘
```

Click to reveal a dropdown showing all desktops with checkmark on the active one.

---

### 2. Desktop Switching

Switcher uses two mechanisms to switch desktops:

**a) Core Graphics (CGS) API**
- Private macOS API to query the Space list
- `CGSCopyManagedDisplaySpaces()` - get all Space IDs
- `CGSGetActiveSpace()` - get current active Space ID

**b) Keyboard Simulation**
- Simulates `Ctrl+1` through `Ctrl+9` key presses
- Uses `CGEvent` to post keyboard events to the system
- This triggers macOS's built-in Mission Control shortcuts

```
Desktop 1 ──Ctrl+1──┐
Desktop 2 ──Ctrl+2──┤
Desktop 3 ──Ctrl+3──┤
   ...              │
Desktop 9 ──Ctrl+9──┴──▶ macOS Space Switching
```

---

### 3. Naming Desktops

Custom names are stored in `~/.config/switcher/spaces.json`:

```json
{
  "names": {
    "123456789": "Work",
    "987654321": "Personal"
  },
  "order": ["123456789", "987654321"]
}
```

**Space ID Migration:**
- After reboot, macOS assigns fresh Space IDs
- On launch, Switcher detects if saved IDs no longer match
- If disjoint (no overlap), it migrates names by position
- "Desktop 1" keeps its name even if the Space ID changes

---

### 4. Global Shortcut

Uses Carbon API to register a system-wide hotkey:

```
⌘⇧W  (default, configurable)
```

When pressed, triggers a click on the menu bar button.

---

### 5. Space List Detection

macOS does not post notifications when desktops are added/removed—only when you switch between them.

Switcher uses two strategies:

| Strategy | Purpose |
|----------|---------|
| `NSWorkspace.activeSpaceDidChangeNotification` | Detects user switching |
| Polling every 1.25s | Detects desktop add/remove |

---

## Key Components

### main.swift
App entry point. Creates an `NSApplication` with `accessory` policy (no Dock icon).

### AppDelegate
- `applicationDidFinishLaunching` - prompts for Accessibility, creates StatusBarManager
- `promptAccessibilityIfNeeded` - triggers the system permission dialog

### StatusBarManager
- Creates and manages the `NSStatusItem` (menu bar button)
- Builds the dropdown menu with all desktops
- Handles menu actions (switch, rename, configure)
- Listens for space change notifications
- Starts the polling timer for add/remove detection

### SpaceManager
- Wraps private CGS API calls
- `desktopSpaceIDs()` - returns all regular desktop Space IDs
- `activeSpaceID()` - returns the current Space ID
- `switchTo(desktopIndex:)` - simulates Ctrl+Number

### SpaceNameStore
- Singleton persisting desktop names to `~/.config/switcher/spaces.json`
- `name(forSpaceID:position:)` - lookup with fallback
- `setName(_:forSpaceID:position:)` - save custom name
- `syncOrder(_:)` - migrate names after reboot

### HotKeyManager
- Singleton using Carbon `RegisterEventHotKey`
- `register(keyCode:modifiers:)` - set global shortcut
- `trigger()` - fires the callback on hotkey press

### ConfigStore
- Singleton persisting shortcut config to `~/.config/switcher/config.json`
- `shortcut` - current ShortcutConfig
- `setShortcut(_:)` - update and persist

---

## Permissions

### Accessibility (Required)
- Needed to simulate keyboard events (Ctrl+1-9)
- App requests on first launch via `AXIsProcessTrustedWithOptions`
- User must grant in **System Settings → Privacy & Security → Accessibility**

### Mission Control Shortcuts (Required)
- `Switch to Desktop 1-9` must be enabled in **Keyboard Shortcuts**
- Without these, Ctrl+Number does nothing

---

## Data Storage

| File | Location | Purpose |
|------|----------|---------|
| `spaces.json` | `~/.config/switcher/` | Desktop names |
| `config.json` | `~/.config/switcher/` | Shortcut config |

---

## Build & Run

```bash
# Development
swift run

# Build DMG
./scripts/mkdmg.sh
```

---

## Limitations

- Maximum **9 desktops** (Ctrl+0 not available)
- Requires Mission Control shortcuts to be enabled
- Accessibility permission must be granted
- Rebuilt apps need Accessibility re-granted (code signature changes)
