# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "brainstorm" - a SwiftUI application for macOS that's part of the AI Study Workbench project. It's a local-first AI-powered study tool designed for researchers, grad students, and lifelong learners to capture ideas, process documents, and maintain focus without context switching.

## Architecture

- **Framework**: SwiftUI with SwiftData for persistence
- **Target Platform**: macOS (14.0+) only
- **Data Model**: Simple SwiftData schema with `Item` entities containing timestamps
- **Bundle ID**: `studio.bns.brainstorm`

### Key Files

- `brainstormApp.swift` - Main app entry point with SwiftData ModelContainer setup
- `ContentView.swift` - Primary navigation interface with master-detail layout
- `Item.swift` - Core data model using SwiftData @Model macro
- `brainstorm.xcodeproj/project.pbxproj` - Xcode project configuration

## Development Commands

### Building
```bash
xcodebuild -project brainstorm.xcodeproj -scheme brainstorm -configuration Debug
```

### Running Tests
```bash
xcodebuild test -project brainstorm.xcodeproj -scheme brainstorm -destination 'platform=macOS'
```

### UI Testing
```bash
xcodebuild test -project brainstorm.xcodeproj -scheme brainstorm -destination 'platform=macOS' -only-testing:brainstormUITests
```

## Development Notes

- The app uses SwiftData for local-first data persistence
- macOS-only application focused on desktop productivity workflows
- The current implementation has evolved to comprehensive packet-based study system
- Takes advantage of macOS-specific features like global hotkeys and window management

## Product Context

This codebase is the foundation for the AI Study Workbench described in `ai_study_workbench_prd_v_2.md`. The final product will include:
- PDF import and parsing
- Voice-to-text capture (⌥ Space hotkey)
- Screen clipping with OCR (⌘⇧C hotkey)
- Brainstorm mode with live transcription
- Local-first AI with optional cloud fallback
- Privacy-focused offline capabilities

## Performance Requirements

Based on the PRD, the app must meet strict performance budgets:
- UI first paint: < 300ms
- PDF parsing (300 pages): ≤ 2s
- Voice note HUD: < 150ms
- Screen clip overlay: < 100ms
- Idle CPU usage: < 2%
- Battery drain while active: < 5%/hour

## Documentation Requirements

**IMPORTANT**: Always update project documentation when making changes:

### CHANGELOG.md
- Update the `[Unreleased]` section for any user-facing changes
- When creating releases, move unreleased items to a new versioned section
- Follow Keep a Changelog format with Added/Changed/Fixed/Removed sections
- Include version numbers and release dates

### DEVLOG.md
- Add entries for each development session with date headers
- Document technical decisions and architecture choices
- Record performance benchmarks and optimization notes
- Note any issues, blockers, or interesting discoveries
- Include next steps or planned work for future sessions

### When to Update
- **After implementing features**: Add to CHANGELOG.md under appropriate category
- **After fixing bugs**: Add to CHANGELOG.md under "Fixed"
- **After making architectural decisions**: Add to DEVLOG.md with rationale
- **After performance work**: Add benchmarks and results to DEVLOG.md
- **At end of development sessions**: Summarize progress in DEVLOG.md