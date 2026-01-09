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
│   │   ├── NewScheduleControls.swift  # Schedule selection UI
│   │   ├── NotificationSlotsEditor.swift # Time slot picker
│   │   ├── SettingsControls.swift     # General app settings
│   │   ├── DeveloperOptions.swift     # Dev tool navigation
│   │   └── [other reusable components]
│   └── Screens/SecretListViewSheets/  # Modal sheets
├── ViewModels/                        # Business logic and state management
│   ├── SecretsViewModel.swift         # Main view model
│   └── SecretsVmDataLoaders.swift     # Storage abstraction
├── Models/                            # Data models
│   ├── Secret.swift                   # Core secret model with encryption
│   ├── SecretCollection.swift         # Collection wrapper
│   ├── ReviewSchedule.swift           # New schedule-based notification system
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
- **Secret Creation**: `Secret.swift` - `init(name:plaintext:)` creates new secret with Argon2 hash
- **Secret Validation**: `Secret.swift` - `validate(plaintextIn:)` method verifies plaintext and updates tracking
- **Quiz Tracking Properties**:
  - `lastQuizzed`: Date - tracks when secret was last validated
  - `lastQuizPassed`: Bool - whether the last quiz attempt succeeded
  - `consecutiveSuccesses`: Int - count of successful validations (resets on failure)
- **Encryption**: Uses Argon2 via libsodium with interactive parameters
- **Hash Migration**: Automatically upgrades legacy SHA512 hashes to Argon2 on validation
- **Add/Remove Secrets**: `SecretsViewModel` methods for secret lifecycle management

### Notifications & Scheduling

#### Review Schedule System
- **Schedule Definition**: `ReviewSchedule.swift` defines expanding interval schedules with configurable notification slots
- **Schedule Calculation**: `nextReviewDate(lastQuizzed:consecutiveSuccesses:)` computes next quiz time based on Fibonacci-like intervals

#### Notification Scheduling Strategy
- **Slot-Based Batch Scheduling**: `SecretsNotificationManager.scheduleBasedOnActiveSchedule()` implements intelligent notification scheduling
  - Schedules up to 15 notifications at once (iOS allows 64 total per app)
  - Looks ahead up to 30 days, checking each configured notification slot
  - For each upcoming slot, checks if any secret is due at or before that slot
  - Only schedules a notification if secrets are due in that time window
  - **Daily Repeating**: All scheduled notifications repeat daily so users get reminded even if they miss the initial notification (e.g., phone off, focus mode)
  - When app launches or user completes a quiz, all notifications are re-registered based on current secret states
- **Notification Identifier Format**: `"quiz.YYYY-MM-DD-HH-MM-SS"` for scheduled quiz notifications

#### Notification Components
- **Notification Manager**: `SecretsNotificationManager` handles scheduled quiz notifications and registration
- **Notification Handling**: `NotificationDelegate.swift` processes tapped notifications
- **Action Handler**: `NotificationActionHandler` singleton coordinates notification actions
- **Base Manager**: `NotificationManager.swift` provides low-level notification APIs
- **Slot Validation**: `validateSlots(_:)` ensures minimum buffer time between notification slots

### Data Storage

#### Storage Architecture
- **Protocol-Based Design**: `SecretsVmDataLoader` protocol enables pluggable storage backends
- **Data Manager**: `SecretsDataManager` handles loading, saving, and demo mode switching
- **Automatic Persistence**: Changes to `@Published` properties trigger `saveItems()` via Combine publishers
- **Storage Configuration**: `Storage.swift` defines `MFAStorage`, `MFFStorage`, `MFUDStorage` (legacy naming)

#### Data Loaders (Strategy Pattern)
1. **SecretsVmDataLoaderFromPlist**: Production/demo plist file storage
   - Implements `SecretsVmDataLoader` protocol
   - Loads/saves `SecretCollection` to property list files
   - Handles serialization/deserialization with Codable
2. **SecretsVmDataLoaderFromArray**: In-memory storage for previews and tests
   - No file I/O, stores secrets in memory array
   - Enables SwiftUI preview functionality

#### Storage Locations
All files stored in app's **Application Support directory** (`.applicationSupportDirectory` in user domain):
- **User Secrets**: `SecretsUser.plist` - production secret data
- **Demo Secrets**: `SecretsDemo.plist` - demo mode secret data (3 example passwords)
- **Legacy Notifications** (deprecated but retained): `RegularIntervalNotifications.plist`, `OneTimeNotifications.plist`

**Backup & Sync Behavior**:
- ❌ **Excluded from device backups**: Files are explicitly excluded from iCloud Backup and iTunes/Finder backups using `NSURLIsExcludedFromBackupKey`
- ❌ **NOT synced via iCloud**: No iCloud Drive or CloudKit integration - data does not sync between devices
- ✅ **On-device-only storage**: Hashed secrets remain exclusively on the device and are not backed up or synced

#### Storage Format
**Property List (Plist) Structure**:
- Root: `SecretCollection` (Codable struct)
- Contains:
  - Array of `Secret` objects with encrypted digests
  - Notification settings (legacy and new schedule-based)
  - Active schedule ID and custom time slots

**What's Stored**:
- Secret `name` (plaintext)
- Secret `digest` (Argon2 or SHA512 hash - NOT plaintext password)
- Secret `digestType` (hash algorithm identifier)
- Quiz tracking: `lastQuizzed`, `lastQuizPassed`, `consecutiveSuccesses`
- Schedule configuration: `availableSchedules`, `activeScheduleId`, `notificationSlots`

**What's NOT Stored**:
- Plaintext passwords (only exist in memory during creation/validation)
- User's master password or key material
- Decryption keys (app uses one-way hashing, not encryption)

#### UserDefaults
**MFUDStorage** manages app preferences:
- `demoMode`: Boolean toggle for demo/production data
- `enableEasterEggs`: Feature flag
- `showDeveloperOptions`: Dev tools visibility
- `showOnboarding`: Onboarding state
- `notificationAction`: Pending notification action state

#### Demo Mode Storage
- Automatic in simulator builds
- Completely separate plist file from production data
- Toggle switches data source without data loss
- `SecretsDataManager.userDefaultsDidChange()` monitors mode changes

### User Interface
- **Main List**: `SecretListView.swift` - displays all secrets and quiz options
- **Quiz Interface**: `Views/Screens/SecretQuiz/` - handles secret validation quizzes with focus management
- **Settings**: `Views/Screens/SecretListViewSheets/SettingsSheet.swift` - main settings container
- **Settings Components** (extracted from main SettingsSheet):
  - `NewScheduleControls.swift` - schedule selection and notification toggle UI
  - `NotificationSlotsEditor.swift` - time slot picker with buffer validation
  - `SettingsControls.swift` - general app toggles and preferences
  - `DeveloperOptions.swift` - developer tool navigation
- **Secret Details**: `SecretDetailView.swift` - individual secret management
- **Modal Sheets**: CreateSecretSheet, OnboardingSheet, DemoModeSheet, AboutSheet
- **Dev Tools**: DevNotifications, DevHapticPlayground, DevTextFieldPlayground

### State Management
- **Publisher Manager**: `SecretsPublisherManager` coordinates Combine publishers and cancellables
- **Reactive Updates**: Published properties in `SecretsViewModel` trigger automatic UI updates
- **Demo Mode Switching**: `SecretsDataManager.userDefaultsDidChange()` handles mode transitions

## Important Implementation Details

### Security

#### Cryptography
- **Argon2 Hashing**: Secrets are hashed using Argon2 with interactive parameters (memory-hard, GPU-resistant)
- **Hash Migration**: Automatically upgrades old SHA512 hashes to Argon2 on validation
- **No Plaintext Storage**: Only one-way hashes are persisted, never plaintext passwords
- **No Master Password**: App uses one-way hashing, not encryption (no key material to protect)

#### Data Protection
- **iOS App Sandbox**: App data isolated from other apps (standard iOS security)
- **On-Device-Only Storage**: Data files are explicitly excluded from device backups using `NSURLIsExcludedFromBackupKey`
  - Hashed secrets remain exclusively on the device
  - Files are stored in Application Support directory
  - Not backed up to iCloud Backup or iTunes/Finder backups
  - If user loses device or deletes app, all secret data is permanently lost
- **No Cloud Sync**: No iCloud Drive or CloudKit - data stays on device only

### Demo Mode
- **Automatic Demo**: Simulator builds automatically enable demo mode
- **Separate Storage**: Demo and production data stored in different plist files
- **Dynamic Switching**: Can toggle between modes with data reloading

### Review Scheduling (Spaced Repetition)
- **ReviewSchedule System**: Enum-based schedule with `ExpandingIntervalSchedule` struct
- **Pre-configured Schedules**:
  - "Expanding Intervals (2x daily)": 9 AM & 6 PM with 6-hour minimum buffer
  - "Expanding Intervals (1x daily)": 9 AM only
- **Fibonacci-like Intervals**: [1, 2, 3, 5, 8, 13, 21, 34] days based on consecutive successes
- **Quiz Tracking**: `lastQuizzed`, `lastQuizPassed`, and `consecutiveSuccesses` properties
- **Notification Slots**: Custom time slots can override schedule defaults with validation

### Additional Features
- **Binary Visualization**: `BinaryDisplay` and `BinaryDisplayConstants` for visualizing data as binary
- **Hash Abstraction**: `Hashes.swift` provides types and utilities for digest operations
- **Date Formatting**: `Date+Formatting.swift` extension for consistent date display
- **Logging**: Centralized logging utilities in `Logging.swift`
- **Context Management**: `RedoubtContext.swift` manages app-wide context and state

### Recent Refactoring (January 2026)
- **Major Scheduling System Overhaul**: Replaced `ScheduleType` enum and `SpacedRepetitionCategory` class with new `ReviewSchedule` enum and `ExpandingIntervalSchedule` struct
- **Removed Files**: `ScheduleType.swift`, `SpacedRepetitionCategory.swift` (~180 lines deleted)
- **Component Extraction**: Separated large SettingsSheet into focused components:
  - `NewScheduleControls.swift` (270+ lines)
  - `NotificationSlotsEditor.swift`
  - `SettingsControls.swift`
  - `DeveloperOptions.swift`
- **Backward Compatibility**: Old notification properties (`regularIntervalNotifications`, `oneTimeNotifications`) retained for legacy data but new schedule system is primary
- **Removed Properties**: `scheduleType`, `spacedRepetitionCategories`, `currentCategory` from `SecretsViewModel` and `SecretCollection`

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
- **Unit Tests**: `RedoubtTests/` - includes cryptography tests and schedule calculation tests
  - `ReviewScheduleTests.swift` - tests expanding interval calculations, never-quizzed scenarios, success tracking
  - `CryptographyTests.swift` - hash and encryption validation
  - `NotificationSchedulingTests.swift` - notification registration logic
- **UI Tests**: `RedoubtUITests/` - end-to-end interface testing
- **Preview Support**: `SecretsVmDataLoaderFromArray` enables SwiftUI previews

## Data Models Deep Dive

### Secret Model
**Type**: Class (reference type for reactive publishing)
**Protocols**: Identifiable, ObservableObject, Codable

**Key Properties**:
- `id: UUID` - computed from name + digest hash for stable identity
- `name: String` - user-visible name
- `digest: String` - Argon2 or SHA512 hash
- `digestType: DigestType` - current hash algorithm (Argon2 or SHA512)
- `lastQuizzed: Date?` - timestamp of last validation
- `lastQuizPassed: Bool` - success status of last quiz
- `consecutiveSuccesses: Int` - count for interval calculation (resets on failure)

**Key Methods**:
- `init(name:plaintext:)` - creates new secret with Argon2 hash
- `update(newPlaintext:)` - updates hash with new plaintext
- `validate(plaintextIn:)` - verifies input, updates tracking, auto-migrates SHA512 to Argon2

### SecretCollection Model
**Type**: Struct (value type)
**Protocol**: Codable

**Properties**:
- `secrets: [Secret]` - array of all secrets
- `regularIntervalNotifications: [DateComponents]` - legacy repeating times
- `oneTimeNotifications: [DateComponents]` - legacy one-time times
- `availableSchedules: [ReviewSchedule]` - configured review schedules
- `activeScheduleId: UUID?` - currently active schedule (nil = disabled)
- `notificationSlots: [DateComponents]?` - custom time slots (nil = use schedule defaults)

**Features**:
- Backward-compatible deserialization for old data format
- Migration support from ScheduleType-based to ReviewSchedule-based system

### ReviewSchedule Enum
**Type**: Enum with associated value
**Protocol**: Codable, Identifiable

**Cases**:
- `.expandingInterval(ExpandingIntervalSchedule)` - wraps expanding interval schedule

**Key Methods**:
- `nextReviewDate(lastQuizzed:consecutiveSuccesses:)` - calculates next quiz time
- `validateSlots(_:)` - validates minimum buffer between notification times
- `formattedMinimumBuffer()` - human-readable buffer description
- `labelForSlot(at:)` - gets label for slot index (e.g., "Morning", "Evening")

### ExpandingIntervalSchedule Struct
**Type**: Struct (value type)
**Protocols**: Codable, Identifiable, Equatable

**Properties**:
- `id: UUID` - immutable identifier
- `name: String` - display name (e.g., "Expanding Intervals (2x daily)")
- `intervals: [Int]` - days between reviews (e.g., [1, 2, 3, 5, 8, 13, 21, 34])
- `defaultSlots: [DateComponents]` - default notification times (e.g., [9:00, 18:00])
- `minimumSlotBuffer: TimeInterval` - minimum seconds between slots (e.g., 21600 = 6 hours)
- `slotLabels: [String]` - labels for each slot (e.g., ["Morning", "Evening"])

**Static Instances**:
- `.default` - 2x daily (9 AM & 6 PM, 6-hour buffer)
- `.onceDaily` - 1x daily (9 AM, no buffer)

**Interval Calculation Logic**:
- Never quizzed: Use first interval (1 day)
- Consecutive successes: Use corresponding interval index (capped at max)
- Failed quiz: Resets consecutiveSuccesses to 0, starts over

## Development Notes
- **Xcode Project**: Standard iOS app structure with `.xcodeproj`
- **Dependencies**: Uses libsodium for Argon2, CryptoKit for other crypto operations
- **Target Environment**: iOS with simulator-specific demo mode behavior
- **Architecture**: Clean separation between UI, business logic, and data persistence
