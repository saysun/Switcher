# Switcher - First-Time Setup Guide

Switcher requires two system configurations before it can function properly.

---

## 1. Enable Accessibility Permission

Switcher simulates `Ctrl+1` through `Ctrl+9` to switch between desktops. This requires **Accessibility** permission.

```
┌─────────────────────────────────────────────────────────────┐
│  System Settings                                            │
│                                                             │
│  [Privacy & Security] ───────────────────────────────────── │
│       │                                                     │
│       ├── [Accessibility]  ◄── You need to add Switcher     │
│       │                      here                           │
│       └── [...]                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Steps:**

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the lock icon and authenticate with your password
3. Click the `+` button
4. Navigate to your Applications folder and select **Switcher**
5. Ensure the toggle next to Switcher is **ON**

```
   ┌─ Accessibility ────────────────────────────────┐
   │                                                │
   │  [+] Add App...                                │
   │                                                │
   │  ┌──────────────────────────────────────────┐  │
   │  │ Switcher                              ON │  │
   │  └──────────────────────────────────────────┘  │
   │                                                │
   └────────────────────────────────────────────────┘
```

---

## 2. Enable Mission Control Keyboard Shortcuts

Switcher relies on the built-in macOS keyboard shortcuts for switching desktops (`Ctrl+1` through `Ctrl+9`). These must be enabled in Mission Control settings.

```
┌─────────────────────────────────────────────────────────────┐
│  System Settings                                            │
│                                                             │
│  [Desktop & Dock] ─────────────────────────────────────     │
│       │                                                     │
│       └── [Mission Control] ──── Configure Spaces here      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Important:** Before enabling shortcuts, first create **9 desktops** in Mission Control. macOS assigns shortcuts only to existing spaces. If you add new desktops later without having 9 created first, those desktops will not have working shortcuts.

```
   Mission Control
   ┌─────────────────────────────────────────────────────┐
   │                                                     │
   │   + Add Desktop   + Add Desktop   + Add Desktop     │
   │   ┌─────────┐     ┌─────────┐     ┌─────────┐       │
   │   │ Desktop │     │ Desktop │     │ Desktop │       │
   │   │    1    │     │    2    │     │    3    │       │
   │   └─────────┘     └─────────┘     └─────────┘       │
   │   ┌─────────┐     ┌─────────┐     ┌─────────┐       │
   │   │ Desktop │     │ Desktop │     │ Desktop │       │
   │   │    4    │     │    5    │     │    6    │       │
   │   └─────────┘     └─────────┘     └─────────┘       │
   │   ┌─────────┐     ┌─────────┐     ┌─────────┐       │
   │   │ Desktop │     │ Desktop │     │ Desktop │       │
   │   │    7    │     │    8    │     │    9    │       │
   │   └─────────┘     └─────────┘     └─────────┘       │
   │                                                     │
   └─────────────────────────────────────────────────────┘
```

**Steps:**

1. Open **System Settings** → **Desktop & Dock** → **Mission Control**
2. Enable "Automatically rearrange Spaces based on most recent use" if desired
3. Create 9 desktops by clicking the `+` button in Mission Control (or by swiping up with 4 fingers and using the `+` button)
4. Then open **System Settings** → **Keyboard** → **Keyboard Shortcuts**
5. Select **Mission Control** from the sidebar
6. Ensure these shortcuts are enabled (checked/active):

```
   ┌─ Mission Control ────────────────────────────┐
   │                                              │
   │   ☑ Switch to Desktop 1         Ctrl + 1     │
   │   ☑ Switch to Desktop 2         Ctrl + 2     │
   │   ☑ Switch to Desktop 3         Ctrl + 3     │
   │   ☑ Switch to Desktop 4         Ctrl + 4     │
   │   ☑ Switch to Desktop 5         Ctrl + 5     │
   │   ☑ Switch to Desktop 6         Ctrl + 6     │
   │   ☑ Switch to Desktop 7         Ctrl + 7     │
   │   ☑ Switch to Desktop 8         Ctrl + 8     │
   │   ☑ Switch to Desktop 9         Ctrl + 9     │
   │                                              │
   │   ☑ Mission Control           Ctrl + ↑       │
   │   ☑ Application Windows        Ctrl + ↓      │
   │                                              │
   └──────────────────────────────────────────────┘
```

> **Note:** You can use different modifiers (e.g., replace `Ctrl` with `⌃ Control`) but whatever is configured here is what Switcher will use.

> **Tip:** After the shortcuts are enabled, you can delete the extra desktops you created for setup. The shortcuts will remain active for however many desktops you keep.

---

## 3. Verify Setup

After completing both steps above, quit and relaunch Switcher. The menu bar should display the current desktop name.

```
   Menu Bar
   ┌────────────────┐
   │ ◆ Desktop 1    │  ◄── Shows current desktop
   └────────────────┘
```

Click the menu item to see all desktops and switch between them.

---

## 4. Optional: Configure Global Shortcut

You can set a custom global shortcut to quickly trigger the Switcher menu from any application.

1. Click the Switcher menu bar icon
2. Select **Configure Shortcut…**
3. Press your desired key combination
4. Click **Save**

```
   ┌─ Configure Shortcut ─────────────────────────┐
   │                                              │
   │   Press a key combination:                   │
   │                                              │
   │        ┌─────────────────┐                   │
   │        │ ⌘⌥S             │                   │
   │        └─────────────────┘                   │
   │                                              │
   │        [Clear]              [Save]           │
   │                                              │
   └──────────────────────────────────────────────┘
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Desktop switching doesn't work | Ensure Accessibility permission is granted |
| Shortcut not responding | Check that the shortcut doesn't conflict with other apps |
| "No desktops detected" | Ensure you have multiple spaces created in Mission Control |
| App appears in Dock | Switcher is a menu-bar only app and should not appear in Dock |
