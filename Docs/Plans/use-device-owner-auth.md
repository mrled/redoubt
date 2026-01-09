# Device Owner Auth Plan for Demo Mode

## Problem
- Demo mode currently requires biometrics (Face/Touch ID) and onboarding attempts to preflight biometrics, which is not possible without prompting.
- We need demo entry/exit to rely on device owner authentication (passcode/biometrics) except in the simulator.
- When device owner auth is unavailable (no passcode), entering or exiting demo must be blocked and clearly communicated in UI.

## Approach
- Replace biometric-only gating with device owner authentication (`.deviceOwnerAuthentication`) and explicit simulator overrides.
- Surface availability status and requirements in the demo sheet (and onboarding) without prompting for auth during onboarding.
- Gate both entry and exit on owner-auth availability (non-simulator). Simulator can always enter/exit regardless of auth status.

## Work Plan (discrete, reviewable steps)
1) **Auth Capability Helper (new utility)**
   - Add a helper that reports: simulator flag, `ownerAuthAvailable` via `.deviceOwnerAuthentication`, lockout state, and unavailable reason (e.g., no passcode).
   - Keep helper self-contained and covered by small unit tests for availability evaluation.

2) **DemoModeSheet Logic and UI Update**
   - Wire the sheet to the helper: entering/exiting allowed only when `ownerAuthAvailable` or running in simulator.
   - Exiting demo triggers owner-auth evaluation; entering/exiting blocked when owner auth unavailable (non-simulator) with a clear alert.
   - Add a single entry/exit function (e.g., `performDemoModeToggleIfAllowed`) that runs the availability checks and flips `@AppStorage`—document that this is the only safe way to enter/exit demo mode and route all toggles through it.
   - Update base copy to state that entering and exiting demo mode require device owner auth.
   - Add bold warning box when `ownerAuthAvailable == false` (non-simulator) explaining entry/exit are blocked until owner auth (passcode) is enabled.
   - Add simulator-only note that entry/exit are always possible without authentication.
   - Handle auth failure/lockout with updated owner-auth terminology.
   - Add/adjust unit tests for sheet logic branching (simulator vs device, available vs unavailable, success vs failure).

3) **Manual QA Pass**
   - Manual verification: simulator (entry/exit without auth, simulator note shown); device with passcode (entry allowed, exit prompts and succeeds); device without passcode (entry/exit blocked, warning shown).

4) **Onboarding/Permissions Cleanup**
   - Remove biometric-specific language or prompts from `PermissionButton` (and related onboarding UI) so onboarding no longer preflights biometrics; align copy with device-owner-auth requirement messaging.
