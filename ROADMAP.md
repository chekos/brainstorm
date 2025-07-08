# AI Study Workbench - Development Roadmap

*Version 1.0 | Created: 2025-07-08*

## Executive Summary

This roadmap outlines the development of AI Study Workbench from its current SwiftUI foundation to a fully-featured local-first AI study tool. The plan prioritizes the three must-have v1 features identified in stakeholder discussions: **Packet Import & Parsing**, **Multi-Modal Capture**, and **Brainstorm Mode**.

**Target**: $1.8M ARR in year 1 with 75k users @ $10/mo (20% capture rate)

---

## Phase 0: Foundation ✅ COMPLETE

**Duration**: 1 day | **Status**: Complete

### Deliverables
- [x] Basic SwiftUI project with SwiftData persistence
- [x] Multi-platform configuration (macOS 14.0+, iOS 18.2+, visionOS 2.2+)
- [x] Documentation structure (CLAUDE.md, CHANGELOG.md, DEVLOG.md)
- [x] Development environment setup

### Success Criteria
- [x] Project builds and runs on macOS
- [x] Basic navigation and item creation/deletion works
- [x] Documentation provides clear guidance for future development

---

## Phase 1: Core Architecture & Data Models

**Duration**: 2-3 weeks | **Priority**: Foundation

### Deliverables
- Enhanced SwiftData models for the full feature set
- Core navigation shell implementation
- Architectural patterns and dependency injection
- Basic UI components library

### Technical Specifications

#### Data Models
```swift
@Model class Packet {
    var id: UUID
    var title: String
    var sourceURL: URL?
    var parsedSections: [PacketSection]
    var checklistItems: [ChecklistItem]
    var createdAt: Date
    var modifiedAt: Date
}

@Model class Capture {
    var id: UUID
    var type: CaptureType // .voice, .screenClip, .brainstorm
    var content: String
    var linkedItems: [ChecklistItem]
    var timestamp: Date
}

@Model class ChecklistItem {
    var id: UUID
    var title: String
    var status: ItemStatus // .pending, .inProgress, .completed
    var pageReference: String?
    var notes: String?
    var captures: [Capture]
}
```

#### Navigation Structure
- Today's Desk (default home screen with sparkline)
- Packet Dashboard (progress overview)
- Individual packet views with checklist display

### Success Criteria
- All data models compile and persist correctly
- Navigation between main views works smoothly
- UI first paint < 300ms (performance budget)
- Basic checklist CRUD operations functional

### Dependencies
- SwiftData schema migration patterns
- iCloud Drive integration research

---

## Phase 2: Packet System - Priority 1

**Duration**: 3-4 weeks | **Priority**: Must-Have v1

### Deliverables
- PDF drag-drop import with visual feedback
- Document parsing into structured checklist
- Rich progress cards with status tracking
- iCloud Drive sync for packet storage

### Technical Specifications

#### PDF Import & Parsing
- **Performance Target**: Parse 300-page PDF ≤ 2s
- **Memory Budget**: Peak RAM during parse < +500MB
- **UI Response**: First paint after drag < 300ms

#### Parsing Strategy (from Q&A)
- **Primary**: Heading-based section detection
- **Secondary**: Heuristic content analysis
- **Fallback**: User highlight learn-mode for edge cases

#### Rich Progress Cards
- Status tags (pending/in-progress/completed)
- Page reference tracking ("p. 123 of 300")
- Free-form notes area
- Screenshot attachment support
- AI summary generation
- Reflection prompts

### User Stories Addressed
- **US-01**: _As a scholar, I drag a ChatGPT-export PDF into Workbench so my study plan turns into actionable tasks._ ✓

### Success Criteria
- PDF import completes within performance budget
- 80%+ headings parsed correctly without user intervention
- Rich progress cards save and sync via iCloud
- Edge case handling (non-English PDFs, malformed documents)

### Risk Mitigation
- Implement chunked parsing for large documents
- Fallback to cloud parsing service if local fails
- Progressive enhancement for complex PDF layouts

---

## Phase 3: Multi-Modal Capture - Priority 2

**Duration**: 4-5 weeks | **Priority**: Must-Have v1

### Deliverables
- Screen clipping with OCR (⌘⇧C hotkey)
- Voice notes with speech-to-text (⌥ Space hotkey)
- Quick capture overlay system
- Linking captures to checklist items

### Technical Specifications

#### Screen Clipping System
- **Performance Target**: Hotkey to overlay < 100ms
- **OCR Speed**: Local OCR on 1080×1080 image ≤ 1s
- **Cloud Fallback**: Round-trip ≤ 3s at 100ms RTT
- **Modal Design**: Fixed 560px width, terracotta accent

#### Voice Notes System
- **Performance Target**: HUD appear < 150ms
- **STT Mode**: Smart hybrid (local first, cloud if low confidence)
- **Streaming**: STT lag < 400ms
- **Summary**: Generation ≤ 3s

#### Quick Capture Overlay
- Cross-hair selection tool
- OCR text extraction with editing
- "Ask AI" with pre-filled "Explain this..." (⌥⇧ held)
- Multi-select checklist linking
- Inline AI answers with follow-up options

### User Stories Addressed
- **US-02**: _I press ⌘⇧C over any region so I can save a snippet and ask "Explain" in one motion._ ✓
- **US-03**: _I hold ⌥ Space to capture a voice idea without leaving my PDF._ ✓

### Success Criteria
- Both capture modes meet performance budgets
- OCR accuracy > 95% on clean text
- Voice transcription accuracy > 90%
- Seamless linking to checklist items
- Offline mode graceful degradation

### Dependencies
- System permissions for screen recording
- Microphone access and privacy compliance
- OCR library evaluation (Vision.framework vs third-party)

---

## Phase 4: Brainstorm Mode - Priority 3

**Duration**: 3-4 weeks | **Priority**: Must-Have v1

### Deliverables
- Live transcript overlay (⌘⇧B hotkey)
- Real-time transcription with visual feedback
- Auto-summarization with dual pane display
- Auto-linking to active checklist items

### Technical Specifications

#### Brainstorm Overlay
- **Performance Target**: Overlay FPS ≥ 60
- **CPU Budget**: Average < 3 of 8 cores
- **Heat Management**: CPU heat triggers cloud STT fallback
- **Visual Design**: Full-screen canvas with live transcript sidebar

#### Live Transcription
- Streaming STT with waveform visualization
- Real-time text display with confidence indicators
- Session chunking for >10 minute recordings
- Auto-save every 30 seconds

#### Auto-Summarization
- Dual pane output: bullet points + narrative paragraph
- Template swapping (user preference)
- Auto-linking to last active checklist item
- Confirmation dialog on session stop

### User Stories Addressed
- **US-04**: _I trigger a continuous transcript canvas so I can free-talk and get an auto-summary._ ✓

### Success Criteria
- Overlay maintains 60 FPS under load
- Transcription accuracy > 85% in brainstorm context
- Auto-linking accuracy > 80%
- Summary quality passes user acceptance testing
- Graceful handling of background noise

### Risk Mitigation
- Fallback to push-to-talk if continuous fails
- Progressive quality degradation under CPU load
- User override for auto-linking decisions

---

## Phase 5: AI Integration

**Duration**: 4-6 weeks | **Priority**: Core Feature

### Deliverables
- Local LLM integration with performance optimization
- Cloud API integration (GPT-4o, Claude 3)
- Hybrid fallback system implementation
- AI answer modals with follow-up chat

### Technical Specifications

#### Local LLM Requirements
- **Memory Budget**: < 4GB footprint
- **Response Time**: ≤ 4s for typical queries
- **Model Selection**: Quantized models suitable for on-device inference
- **Thermal Management**: Throttling to prevent overheating

#### Cloud Integration
- GPT-4o and Claude 3 API integration
- Token usage tracking and cost optimization
- Smart routing based on query complexity
- Graceful degradation during API outages

#### Hybrid System
- **Default**: Cloud-first for accuracy and speed
- **Fallback**: Local when offline or API unavailable
- **User Control**: Toggle for local-only mode (⌥P)
- **Context Management**: Smart context truncation for token limits

### Success Criteria
- Local LLM responses within performance budget
- Cloud API integration with 99.9% uptime handling
- Seamless fallback with user notification
- Context preservation across different AI backends

### Dependencies
- Model licensing and distribution rights
- API rate limiting and cost management
- Performance benchmarking on target hardware

---

## Phase 6: Visual Polish & Performance

**Duration**: 3-4 weeks | **Priority**: Launch Readiness

### Deliverables
- Complete visual design implementation
- Performance optimization to meet all PRD budgets
- Accessibility compliance (WCAG 2.1)
- Edge case handling and error recovery

### Design Implementation
- **Typography**: IBM Plex Serif primary, Berkeley Mono TX-02 for code
- **Color Scheme**: Terracotta accent (#C86F55), subtle parchment tint
- **Animations**: Micro-animations, 120ms fade-in, 90ms fade-out
- **Layout**: Minimalist, calm notebook aesthetic

### Performance Validation
- All PRD performance budgets met consistently
- Battery drain while active < 5%/hour
- Idle CPU usage < 2%
- Memory usage optimization
- Crash-free hours > 100

### Success Criteria
- Design passes user experience testing
- Performance benchmarks exceed targets
- Accessibility audit complete
- Error handling covers 95% of edge cases

---

## Phase 7: Launch Preparation

**Duration**: 2-3 weeks | **Priority**: Business Critical

### Deliverables
- Pricing/subscription integration
- App Store preparation and review
- Testing and QA completion
- Launch marketing assets

### Business Integration
- **Local-Only Plan**: $49 one-time purchase
- **Pro Plan**: $10/month subscription
- In-app purchase implementation
- Usage analytics and telemetry

### Quality Assurance
- Comprehensive testing across all supported platforms
- Performance validation on minimum hardware
- User acceptance testing with target audience
- Security audit and privacy compliance

### User Stories Validation
- **US-05**: _I open a single screen to review everything captured in the last 24h._ ✓
- **US-06**: _I swap to progress view to see overall task status._ ✓  
- **US-07**: _I switch the app offline when I'm on a plane._ ✓

### Success Criteria
- All user stories completed and tested
- App Store approval achieved
- Launch marketing materials ready
- Support documentation complete

---

## Phase 8: Post-Launch Expansion

**Duration**: Ongoing | **Priority**: Growth

### Planned Features
- Advanced analytics and insights
- Template system for different study types
- Knowledge base integration
- Platform expansion (iOS, visionOS native features)
- Team collaboration features

### Business Metrics
- Monthly recurring revenue tracking
- User retention and engagement metrics
- Feature usage analytics
- Customer feedback integration

---

## Risk Management

### Technical Risks
- **Local LLM Performance**: Mitigation through careful model selection and optimization
- **PDF Parsing Accuracy**: Fallback to cloud services and user correction workflows
- **Platform Compatibility**: Extensive testing across hardware configurations

### Business Risks
- **Market Adoption**: Closed beta with target users before launch
- **Pricing Sensitivity**: A/B testing of pricing models
- **Competition**: Differentiation through local-first approach and performance

### Timeline Risks
- **Scope Creep**: Strict adherence to must-have features for v1
- **Dependencies**: Parallel development where possible
- **Quality Gates**: Performance budgets as hard requirements

---

## Success Metrics

### Technical KPIs
- All performance budgets met consistently
- 99.9% uptime for critical features
- < 0.1% crash rate
- User satisfaction > 4.5/5 in app reviews

### Business KPIs
- 75k users by end of year 1
- $1.8M ARR target achievement
- 20% freemium to paid conversion
- < 5% monthly churn rate

---

## Next Steps

1. **Phase 1 Kickoff**: Begin enhanced data model implementation
2. **Architecture Review**: Validate technical approach with stakeholders
3. **Performance Baseline**: Establish current performance metrics
4. **User Research**: Conduct interviews with target users for Phase 2

*Last updated: 2025-07-08*