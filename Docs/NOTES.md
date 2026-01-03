# Redoubt - Code Organization and Architecture

## Overview

Redoubt is an iOS SwiftUI app for secure password/secret memorization through spaced repetition and scheduled notifications. Users store encrypted secrets and get quizzed on them at configured intervals to improve memorization. The app uses strong cryptographic hashing (Argon2) and supports both regular use and demo modes.

## High-Level Architecture

### Core Components
- **SwiftUI Views**: User interface built with SwiftUI and MVVM pattern
- **SecretsViewModel**: Central view model coordinating managers and app state
- **Secret Model**: Core data model representing encrypted secrets
- **Manager Classes**:
  - `SecretsNotificationManager`: Handles scheduled quiz notifications
  - `SecretsDataManager`: Manages data persistence and demo mode
  - `SecretsPublisherManager`: Coordinates Combine publishers
- **Storage System**: Pluggable data persistence using property lists

### Key Design Patterns
- **MVVM**: Views observe ViewModels using `@EnvironmentObject` and `@StateObject`
- **Publisher/Subscriber**: Reactive updates using Combine framework
- **Protocol-based Storage**: `SecretsVmDataLoader` protocol allows swapping storage backends
- **Singleton Managers**: NotificationManager and NotificationActionHandler use shared instances

## Project Structure

```
Redoubt/
├── RedoubtApp.swift                   # App entry point and initialization
├── Delegates/                         # Notification handling
│   └── NotificationDelegate.swift
├── Views/                             # SwiftUI user interface
│   ├── Screens/                       # Main view controllers
│   │   ├── ContentView.swift          # Root view
│   │   ├── SecretListView.swift       # Main secrets list
│   │   ├── SecretDetailView.swift     # Individual secret details
│   │   └── SecretQuiz/                # Quiz functionality
│   ├── Components/                    # Reusable UI components
│   └── Screens/SecretListViewSheets/  # Modal sheets
├── ViewModels/                        # Business logic and state management
│   ├── SecretsViewModel.swift         # Main view model
│   └── SecretsVmDataLoaders.swift     # Storage abstraction
├── Models/                            # Data models
│   ├── Secret.swift                   # Core secret model with encryption
│   ├── SecretCollection.swift         # Collection wrapper
│   ├── SpacedRepetitionCategory.swift # Spaced repetition intervals
│   ├── ScheduleType.swift             # Notification schedule types
│   ├── Hashes.swift                   # Hash/digest types and utilities
│   ├── BinaryDisplay.swift            # Binary data visualization
│   └── BinaryDisplayConstants.swift   # Binary display configuration
├── Storage/                           # Data persistence
│   ├── Storage.swift                  # Storage configuration
│   ├── SecretsDataManager.swift       # Secrets data operations
│   └── UserDefaultsWrappers.swift     # UserDefaults wrappers
├── Managers/                          # System integration
│   ├── NotificationManager.swift      # iOS notification handling
│   └── SecretsNotificationManager.swift # Secret-specific notifications
├── Observables/                       # Reactive state objects
│   ├── NotificationList.swift         # Notification list state
│   ├── NotificationActionHandler.swift # Notification action handling
│   └── SecretsPublisherManager.swift  # Publisher coordination
├── Helpers/                           # Utility functions
│   ├── NotificationHelpers.swift      # Notification utilities
│   ├── Logging.swift                  # Logging utilities
│   ├── RedoubtUtilities.swift         # General utilities
│   └── RedoubtContext.swift           # App context management
└── Extensions/                        # Swift extensions
    └── Date+Formatting.swift          # Date formatting extensions
```

## Key Functionality Locations

> Note: Line numbers are approximate and may change as the codebase evolves. Use them as guidance for locating functionality.

### Secret Management
- **Secret Creation**: `Secret.swift:96` - `init(name:plaintext:spacedRepetitionCategory:)`
- **Secret Validation**: `Secret.swift:122` - `validate(plaintextIn:)` method
- **Encryption**: Uses Argon2 via libsodium (`Secret.swift:101`)
- **Add/Remove Secrets**: `SecretsViewModel.swift:69` and `SecretsViewModel.swift:74`

### Notifications & Scheduling
- **Notification Manager**: `SecretsNotificationManager` handles scheduled quiz notifications
- **Notification Handling**: `NotificationDelegate.swift` processes tapped notifications
- **Action Handler**: `NotificationActionHandler` singleton coordinates notification actions
- **Base Manager**: `NotificationManager.swift` provides low-level notification APIs

### Data Storage
- **Data Manager**: `SecretsDataManager` handles loading, saving, and demo mode switching
- **Data Loading**: `SecretsVmDataLoaders.swift` - `SecretsVmDataLoaderFromPlist.load()`
- **Data Saving**: Automatic persistence via `saveItems()` triggered by published property changes
- **Storage Configuration**: `Storage.swift` - `MFAStorage` keys and defaults (legacy naming)
- **Demo Mode**: Separate plists (`SecretsUser.plist` vs `SecretsDemo.plist`) managed by `SecretsDataManager`

### User Interface
- **Main List**: `SecretListView.swift` - displays all secrets and quiz options
- **Quiz Interface**: `Views/Screens/SecretQuiz/` - handles secret validation quizzes
- **Settings**: `Views/Screens/SecretListViewSheets/SettingsSheet.swift`
- **Secret Details**: `SecretDetailView.swift` - individual secret management
- **Dev Tools**: Various Dev* sheets for testing (haptics, text fields, notifications)

### State Management
- **Publisher Manager**: `SecretsPublisherManager` coordinates Combine publishers and cancellables
- **Reactive Updates**: Published properties in `SecretsViewModel` trigger automatic UI updates
- **Demo Mode Switching**: `SecretsDataManager.userDefaultsDidChange()` handles mode transitions

## Important Implementation Details

### Security
- **Argon2 Hashing**: Secrets are hashed using Argon2 with interactive parameters
- **Hash Migration**: Automatically upgrades old SHA512 hashes to Argon2 on validation
- **No Plaintext Storage**: Only encrypted digests are persisted

### Demo Mode
- **Automatic Demo**: Simulator builds automatically enable demo mode
- **Separate Storage**: Demo and production data stored in different plist files
- **Dynamic Switching**: Can toggle between modes with data reloading

### Spaced Repetition
- **Categories**: Pre-defined time intervals (daily, weekly, monthly, etc.)
- **Quiz Tracking**: `lastQuizzed` property tracks when secrets were last validated
- **Schedule Types**: `ScheduleType` enum defines notification scheduling strategies

### Additional Features
- **Binary Visualization**: `BinaryDisplay` and `BinaryDisplayConstants` for visualizing data as binary
- **Hash Abstraction**: `Hashes.swift` provides types and utilities for digest operations
- **Date Formatting**: `Date+Formatting.swift` extension for consistent date display
- **Logging**: Centralized logging utilities in `Logging.swift`
- **Context Management**: `RedoubtContext.swift` manages app-wide context and state

### Data Flow
1. **App Launch**: `RedoubtApp.swift` initializes `SecretsViewModel` with appropriate data loader
2. **Manager Initialization**: ViewModel creates and links manager instances:
   - `SecretsDataManager` for persistence
   - `SecretsNotificationManager` for notifications
   - `SecretsPublisherManager` for reactive state
3. **Data Loading**: `SecretsDataManager` loads secrets from plist via `SecretsVmDataLoaders`
4. **Reactive Updates**: `SecretsPublisherManager` sets up Combine publishers for state changes
5. **Persistence**: Changes to `@Published` properties trigger `saveItems()` in `SecretsDataManager`
6. **Notifications**: State changes trigger notification re-registration via `SecretsNotificationManager`

## Testing Structure
- **Unit Tests**: `RedoubtTests/` - includes cryptography tests
- **UI Tests**: `RedoubtUITests/` - end-to-end interface testing
- **Preview Support**: `SecretsVmDataLoaderFromArray` enables SwiftUI previews

## Development Notes
- **Xcode Project**: Standard iOS app structure with `.xcodeproj`
- **Dependencies**: Uses libsodium for Argon2, CryptoKit for other crypto operations
- **Target Environment**: iOS with simulator-specific demo mode behavior
- **Architecture**: Clean separation between UI, business logic, and data persistence
