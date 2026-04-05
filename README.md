# Switcher

A lightweight macOS menu bar app for naming and switching between desktop Spaces.

<img width="482" height="416" alt="image" src="https://github.com/user-attachments/assets/5b694efc-04d8-4a5c-bcac-e455447b2827" />
<img src="Resources/screenshot2.png" width="500" alt="Rename Panel">

https://www.youtube.com/watch?v=DZfzuiSTXr4

## Features

- Shows current desktop name in the menu bar
- Lists all desktops in a dropdown menu
- Click to switch between desktops (1–9)
- Rename any desktop with custom names
- Names persist across app restarts

## Requirements

- macOS 13.0+ (Ventura or later)
- Swift 5.9+
- "Switch to Desktop X" shortcuts enabled in System Settings

## Setup

### 1. download installer from release (https://github.com/saysun/Switcher/releases)
### 2. install by clicking the Switcher installer.
### 3. open the Switcher app in Applications
On first launch, macOS will ask for **Accessibility** permission. Grant it so Switcher can
simulate keyboard shortcuts to switch desktops.
### 4. Enable Desktop Switching Shortcuts
Go to **System Settings → Keyboard → Keyboard Shortcuts → Mission Control** and enable
"Switch to Desktop 1" through "Switch to Desktop 9" (or however many you use).

Set up Video: 
https://www.youtube.com/watch?v=TM1FQi0uFHo


## Usage

- **Menu bar** shows `◆ <current desktop name>`
- **Click** the menu bar item to see all desktops (or use shortcut key)
- **Click a desktop** to switch to it (or num + enter)
- **Rename Desktop → pick a desktop** to give it a custom name

## Configuration

Desktop names are stored in `~/.config/switcher/spaces.json`.
