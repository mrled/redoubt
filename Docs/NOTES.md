# MindFort - Code Organization and Architecture

## Overview

MindFort is an iOS SwiftUI app for secure password/secret memorization through spaced repetition and scheduled notifications. Users store encrypted secrets and get quizzed on them at configured intervals to improve memorization. The app uses strong cryptographic hashing (Argon2) and supports both regular use and demo modes.

## High-Level Architecture

### Core Components
- **SwiftUI Views**: User interface built with SwiftUI and MVVM pattern
- **SecretsViewModel**: Central view model managing all app state and business logic
- **Secret Model**: Core data model representing encrypted secrets
- **NotificationManager**: Handles scheduled quiz notifications
- **Storage System**: Pluggable data persistence using property lists

### Key Design Patterns
- **MVVM**: Views observe ViewModels using `@EnvironmentObject` and `@StateObject`
- **Publisher/Subscriber**: Reactive updates using Combine framework
- **Protocol-based Storage**: `SecretsVmDataLoader` protocol allows swapping storage backends
- **Singleton Managers**: NotificationManager and NotificationActionHandler use shared instances

## Project Structure

```
MindFort/
├── MindFortApp.swift              # App entry point and initialization
├── Delegates/                     # Notification handling
│   └── NotificationDelegate.swift
├── Views/                         # SwiftUI user interface
│   ├── Screens/                   # Main view controllers
│   │   ├── ContentView.swift      # Root view
│   │   ├── SecretListView.swift   # Main secrets list
│   │   ├── SecretDetailView.swift # Individual secret details
│   │   └── SecretQuiz/            # Quiz functionality
│   ├── Components/                # Reusable UI components
│   └── Screens/SecretListViewSheets/ # Modal sheets
├── ViewModels/                    # Business logic and state management
│   ├── SecretsViewModel.swift     # Main view model
│   └── SecretsVmDataLoaders.swift # Storage abstraction
├── Models/                        # Data models
│   ├── Secret.swift               # Core secret model with encryption
│   ├── SecretCollection.swift     # Collection wrapper
│   └── SpacedRepetitionCategory.swift
├── Storage/                       # Data persistence
│   ├── Storage.swift              # Storage configuration
│   └── UserDefaultsWrappers.swift
├── Managers/                      # System integration
│   └── NotificationManager.swift  # iOS notification handling
├── Helpers/                       # Utility functions
└── Observables/                   # Reactive state objects
```

## Key Functionality Locations

### Secret Management
- **Secret Creation**: `Secret.swift:103` - `init(name:plaintext:spacedRepetitionCategory:)`
- **Secret Validation**: `Secret.swift:129` - `validate(plaintextIn:)` method
- **Encryption**: Uses Argon2 via libsodium (`Secret.swift:108`)
- **Add/Remove Secrets**: `SecretsViewModel.swift:198` and `SecretsViewModel.swift:207`

### Notifications & Scheduling
- **Notification Registration**: `NotificationManager.swift:37` - `registerNotification()`
- **Quiz Scheduling**: `SecretsViewModel.swift:299` - `reregisterAllNotifications()`
- **Notification Handling**: `NotificationDelegate.swift` processes tapped notifications
- **Time Scheduling**: `SecretsViewModel.swift:252` and `SecretsViewModel.swift:235` for regular/one-time notifications

### Data Storage
- **Data Loading**: `SecretsVmDataLoaders.swift:29` - `SecretsVmDataLoaderFromPlist.load()`
- **Data Saving**: `SecretsVmDataLoaders.swift:41` - `save(collection:)`
- **Storage Configuration**: `Storage.swift:13` - `MFAStorage` keys and defaults
- **Demo Mode**: Separate data files for demo vs production (`SecretsViewModel.swift:74-77`)

### User Interface
- **Main List**: `SecretListView.swift` - displays all secrets and quiz options
- **Quiz Interface**: `Views/Screens/SecretQuiz/` - handles secret validation quizzes
- **Settings**: `Views/Screens/SecretListViewSheets/SettingsSheet.swift`
- **Secret Details**: `SecretDetailView.swift` - individual secret management

### State Management
- **Reactive Updates**: `SecretsViewModel.swift:159` - `setupPublishers()` for reactive state
- **Publisher Cancellables**: `SecretsViewModel.swift:54` - manages Combine subscriptions
- **Demo Mode Switching**: `SecretsViewModel.swift:183` - `userDefaultsDidChange()`

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
- **Future Enhancement**: Spaced repetition notification scheduling (TODO at line 315)

### Data Flow
1. **App Launch**: `MindFortApp.swift` initializes `SecretsViewModel` with appropriate data loader
2. **Data Loading**: ViewModel loads secrets from plist via `SecretsVmDataLoaders`
3. **Reactive Updates**: Publishers notify views when data changes
4. **Persistence**: Changes automatically saved via `saveItems()` triggered by publishers
5. **Notifications**: Changes trigger notification re-registration for scheduling

## Testing Structure
- **Unit Tests**: `MindFortTests/` - includes cryptography tests
- **UI Tests**: `MindFortUITests/` - end-to-end interface testing
- **Preview Support**: `SecretsVmDataLoaderFromArray` enables SwiftUI previews

## Development Notes
- **Xcode Project**: Standard iOS app structure with `.xcodeproj`
- **Dependencies**: Uses libsodium for Argon2, CryptoKit for other crypto operations
- **Target Environment**: iOS with simulator-specific demo mode behavior
- **Architecture**: Clean separation between UI, business logic, and data persistence
