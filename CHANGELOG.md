# Changelog

All notable changes to the AI Study Workbench (brainstorm) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive SwiftData models (Packet, PacketSection, ChecklistItem, Capture)
- Core navigation shell with Today's Desk and Packet Dashboard
- Enhanced UI components (ProgressCardView, CaptureTypeIcon, HotkeyLabel)
- Service layer architecture with DataService and ServiceContainer
- Rich progress tracking with status indicators
- Multi-modal capture type system
- Architectural patterns for dependency injection
- PDF drag-drop import functionality with visual feedback
- PDF parsing service with intelligent section detection
- Auto-checklist generation from parsed document content
- Section viewer with detailed content display
- Import progress tracking and error handling
- Voice notes capture with ⌥Space hotkey and speech recognition
- Screen clipping with ⌘⇧C hotkey and OCR text extraction
- Brainstorm mode with ⌘⇧B hotkey and live transcription overlay
- Capture HUD for managing all capture modes and permissions
- Global hotkey service using Carbon Event Manager
- Multi-modal capture linking to packets and checklist items
- Rich progress cards with interactive visual design and status indicators
- Enhanced packet overview cards with comprehensive statistics and quick actions
- AI-powered PDF parsing with OpenAI GPT-4o integration
- AI Settings interface for API key configuration and service management
- Smart AI service routing with fallback to mock service
- Comprehensive typography and spacing improvements for better readability

### Changed
- Replaced basic Item model with comprehensive feature-ready data models
- Updated ContentView to use new MainNavigationView
- Enhanced navigation with sidebar packet list and status tracking
- Upgraded typography scale from caption-heavy fonts to proper readable hierarchy
- Improved spacing and padding across all UI components for better visual clarity
- Enhanced visual hierarchy in progress cards and detail views

### Fixed
- Build configuration issues for local development without Apple Developer account
- SwiftData circular reference errors in model relationships
- Platform-specific UI issues (iOS-only navigation modifiers on macOS)
- Color system compatibility issues between iOS and macOS
- VoiceService macOS compatibility (removed iOS-specific AVAudioSession APIs)
- HotkeyService Carbon API type conversion errors for global shortcuts
- SwiftData import issues in CaptureHUD for FetchDescriptor usage
- @MainActor isolation for SFSpeechRecognizerDelegate protocol compliance
- Critical UI readability issues with extremely small, hard-to-read text throughout interface
- Layout frame constraints preventing proper space utilization in PacketDetailView
- Missing AI Settings button visibility in main navigation sidebar
- Memory management crashes during CaptureHUD service initialization
- Privacy permissions for speech recognition and microphone access
- SwiftData relationship management crashes in PDF import workflow

### Removed
- Basic Item.swift model (replaced with comprehensive models)
- CloudKit and app sandboxing entitlements (simplified for local development)

## [0.1.0] - 2025-07-08

### Added
- Initial Xcode project setup
- Basic SwiftData model (`Item` with timestamp)
- SwiftUI `ContentView` with list navigation
- Cross-platform toolbar adaptations
- Test target configurations (unit and UI tests)

---

## Template for Future Entries

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```