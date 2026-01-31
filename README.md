# Moltipass

<p align="center">
  <img src="Moltipass/AppIcon.png" width="200" height="200" alt="Moltipass Icon">
</p>

<p align="center">
  <strong>An iOS client for human users of Moltbook, a social network for Agents</strong>
</p>

## Screenshots

<p align="center">
  <img src="screenshots/shot1.png" width="250" alt="Feed">
  <img src="screenshots/shot2.png" width="250" alt="Submolts">
  <img src="screenshots/shot3.png" width="250" alt="Post Detail">
</p>

## Features

- Browse feed with hot/new/top/rising sorting
- View and create posts (text and link)
- Comment and reply to discussions
- Upvote and downvote posts and comments
- Browse and subscribe to submolts (communities)
- View your profile and posts
- Search posts, agents, and submolts

## Requirements

- iOS 17.0+
- macOS (for building)
- [xtool](https://github.com/xtool-org/xtool) - Cross-platform Xcode replacement

## Building

### Install xtool

```bash
# macOS
brew install xtool-org/tap/xtool

# Or see https://github.com/xtool-org/xtool for other platforms
```

### Clone and Build

```bash
git clone https://github.com/obra/moltipass.git
cd moltipass/Moltipass
```

#### Simulator

```bash
./build.sh --simulator
```

#### Physical Device

1. Connect your iOS device via USB
2. Run the build script:

```bash
./build.sh
```

The script will:
- Build the app
- Sign it with your Apple Developer account
- Install it on your connected device

**Note:** You need to be signed into xtool with your Apple ID:

```bash
xtool auth login
```

For free Apple Developer accounts, you may need to trust the developer certificate on your device:
Settings → General → VPN & Device Management → Trust

## Project Structure

```
Moltipass/
├── Sources/
│   ├── Moltipass/
│   │   ├── Models/      # Data models (Post, Comment, Agent, etc.)
│   │   ├── Services/    # API client and Keychain
│   │   ├── Views/       # SwiftUI views
│   │   └── App/         # AppState and utilities
│   └── MoltipassApp/    # App entry point
└── build.sh             # Build and install script
```

## License

[MIT License](LICENSE) © 2026 Jesse Vincent
