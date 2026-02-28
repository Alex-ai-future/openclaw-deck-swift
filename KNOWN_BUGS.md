# Known Bugs

This document tracks known issues and bugs in the OpenClaw Deck Swift project.

## Purpose

This file serves as a central reference for:
- **Documenting known issues** that have been identified but not yet fixed
- **Tracking workarounds** for temporary solutions
- **Providing visibility** into current limitations of the application
- **Helping prioritize** bug fixes during development

## Format

Each bug entry should include:
- **ID**: Unique identifier (e.g., BUG-001)
- **Title**: Brief description of the issue
- **Severity**: Critical / High / Medium / Low
- **Status**: Open / In Progress / Resolved
- **Description**: Detailed explanation of the bug
- **Reproduction Steps**: How to reproduce the issue
- **Workaround**: Any temporary solutions (if available)
- **Date Reported**: When the bug was discovered

---

## Current Known Issues

### BUG-001: Session List Not Displaying on iPhone

- **ID**: BUG-001
- **Title**: Session list does not display in iPhone app
- **Severity**: High
- **Status**: Open
- **Description**: The session list view fails to render or display any session records when running the app on iPhone. The list appears empty or does not load at all.
- **Reproduction Steps**:
  1. Build and run the app on iPhone device or simulator
  2. Navigate to the session list view
  3. Observe that no sessions are displayed
- **Workaround**: None currently available
- **Date Reported**: 2026-02-28
- **Platform**: iOS (iPhone)
- **Notes**: This issue appears to be specific to the iOS build. Further investigation needed to determine if it's a data fetching issue, UI rendering problem, or platform-specific bug.

### BUG-002: Settings Buttons Not Responding on iPhone

- **ID**: BUG-002
- **Title**: Settings cancel and confirm buttons not responding on iPhone
- **Severity**: High
- **Status**: Open
- **Description**: When tapping the Cancel or Confirm buttons in the settings view within the session list on iPhone, the buttons do not respond to touch events. No action is taken when tapped.
- **Reproduction Steps**:
  1. Build and run the app on iPhone device or simulator
  2. Navigate to the session list view
  3. Tap on the settings button/icon for a session
  4. Tap either Cancel or Confirm button in the settings dialog
  5. Observe that buttons do not respond
- **Workaround**: None currently available
- **Date Reported**: 2026-02-28
- **Platform**: iOS (iPhone)
- **Notes**: This may be related to button action binding issues, gesture recognizer conflicts, or UI event handling problems specific to iOS.

### BUG-003: Session Navigation Not Working After Manual Add

- **ID**: BUG-003
- **Title**: Cannot navigate to session detail after manually adding a session
- **Severity**: High
- **Status**: Open
- **Description**: After manually adding a new session to the session list, the session appears in the list but tapping on it does not navigate to the corresponding session detail page. The tap action has no effect.
- **Reproduction Steps**:
  1. Build and run the app
  2. Manually add a new session to the session list
  3. Observe that the new session appears in the list
  4. Tap on the newly added session
  5. Observe that navigation to the session detail page does not occur
- **Workaround**: None currently available
- **Date Reported**: 2026-02-28
- **Platform**: iOS (iPhone)
- **Notes**: This suggests the manually added session may be missing required navigation data, binding, or the tap gesture handler is not properly configured for dynamically added items.

---

## Resolved Issues

*Resolved bugs will be moved here with a note about the fix.*

