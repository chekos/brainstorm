# AI Study Workbench – Product Requirements Document (v2 DRAFT)

_Last updated: 8 July 2025_

---

## 0 · Document Meta

- **Author / PM:** Sergio Sanchez
- **Tech Lead:** TBD
- **Design Lead:** TBD
- **QA Lead:** TBD
- **Stakeholders:** Exec sponsor, Growth, Support

**Change‑log**

- **v1 (PDF)**         Initial rough spec
- **v2 (this doc)**  Consolidates all discussion artefacts & adds perf budgets, wireframes, user stories

---

## 1 · Problem Statement (the “why”)

Self‑directed learners—grad students, indie researchers, and lifelong geeks—bounce between ChatGPT chats, PDF readers, and ad‑hoc note apps just to capture a single insight. Context switches shred focus; half‑formed ideas scatter, and deep dives stall out.

**AI Study Workbench** collapses chat, quick capture (voice ▸ text, screenshots ▸ OCR), and local‑first AI into one calm Mac workspace so users stay in flow and deliver deeper work—without surrendering privacy.

---

## 2 · Business Rationale

- **Target users:** Mac‑centric “knowledge‑power” crowd (researchers, grad students, domain hobbyists).
- **Addressable slice:** ≈ **75 k** English‑speaking Mac users who already pay for at least one study tool.
- **Entry ARR hypothesis:** 75 k × **\$10 / mo** × **20 %** realistic capture → **\$1.8 M ARR** in year 1.
- **Why now:**
  - Apple Silicon makes on‑device LLMs viable.
  - Mainstream note apps keep data in cloud silos.
  - Privacy regulations tilt adoption toward “local‑first.”
- **Strategic upside:**
  - Upsell Windows & iPad ports (v2).
  - License the quick‑capture SDK.
  - Academic volume seats.

### 2·1 Pricing Hypothesis (two‑tier)

- **Local‑Only Plan** — one‑time **\$49**; uses bundled llama‑based models only.
- **Pro Plan** — **\$10 / mo**; unlocks GPT‑4o / Claude 3 calls, high‑accuracy Whisper, faster model refresh, priority support.

---

## 3 · Competitive Gap Snapshot

- **ChatGPT Projects:** stellar reasoning UI → _blind spot: still chat‑centric, no offline capture._
- **Readwise Reader:** great reading queue → _blind spot: no voice / screenshot capture; cloud only._
- **Obsidian + plugins:** deep linking → _blind spot: DIY plugin soup, steep learning curve, no turnkey AI._

---

## 4 · Goals & High‑Level Success Metrics _(TBD)_

_After the Problem + Business sections are finalised, rewrite each goal with a measurable KPI (e.g., “≥ 80 % documents parsed unaided”)._

---

## 5 · Feature Detail

### 5·1 User Stories (v1 set)

- **US‑01 – Import & parse PDF**: _As a scholar, I drag a ChatGPT‑export PDF into Workbench so my study plan turns into actionable tasks._ ↳ Done = checklist appears in ≤ 2 s.
- **US‑02 – Quick screen clip**: _I press ⌘⇧C over any region so I can save a snippet and ask “Explain” in one motion._
- **US‑03 – Push‑to‑talk memo**: _I hold ⌥ Space to capture a voice idea without leaving my PDF._
- **US‑04 – Brainstorm mode**: _I trigger a continuous transcript canvas so I can free‑talk and get an auto‑summary._
- **US‑05 – Today’s Desk**: _I open a single screen to review everything captured in the last 24 h._
- **US‑06 – Packet Dashboard**: _I swap to progress view to see overall task status._
- **US‑07 – Local‑only toggle**: _I switch the app offline when I’m on a plane._

### 5·2 End‑to‑End Flows (happy‑path + edge‑cases)

- **Flow A – First launch & packet import**: drag PDF → parsing spinner → checklist; handle “< 80 % headings” edge case with review sheet.
- **Flow B – Quick clip + Ask‑AI**: ⌘⇧C → cross‑hair select → modal with OCR + answer; offline fallback to llama if no internet.
- **Flow C – Voice note**: hold ⌥ Space → HUD mic → STT → transcript saved; chunk upload if > 10 min.
- **Flow D – Brainstorm**: ⌘⇧B → overlay + live transcript → stop = summary & links; CPU heat triggers cloud STT fallback.
- **Flow E – Daily review**: open Desk → capture list + sparkline → drag card status; iCloud lag banner if sync > 30 s.

### 5·3 UX Annotations

- Clip modal width fixed at 560 px.
- Accent terracotta #C86F55 for all AI buttons.
- Modal fade‑in 120 ms, fade‑out 90 ms to maintain “calm notebook” vibe.

### 5·4 Known Gaps / TODOs

- Empty‑state artwork (Desk & Dashboard).
- Final checklist card fields (status, pages, reflection?).
- On‑device llama model must stay < 4 GB.
- Decide onboarding method (static copy vs coach marks).

---

## 6 · Non‑Functional Requirements

### 6·1 Performance Budgets

- **Packet import**
  - UI first paint after drag = < 300 ms.
  - Parse 300‑page PDF ≤ 2 s.
  - Peak RAM during parse < +500 MB.
- **Quick clip**
  - Hotkey to overlay < 100 ms.
  - Local OCR on 1080×1080 image ≤ 1 s.
  - Cloud fallback round‑trip ≤ 3 s at 100 ms RTT.
- **Voice note**
  - HUD appear < 150 ms.
  - Streaming STT lag < 400 ms.
  - Summary generation ≤ 3 s.
- **Brainstorm overlay**
  - Overlay FPS ≥ 60.
  - Average CPU < 3 of 8 cores.
- **Daily review**
  - Desk load < 800 ms.
  - Local llama answer ≤ 4 s.
- **Global**
  - Idle CPU < 2 %.
  - Battery drain while active < 5 % / hr.
  - Crash‑free hours > 100.

### 6·2 Measurement & CI Plan

- `--perf-debug` flag dumps JSON timestamps for every milestone.
- CI gate blocks PRs if baseline M1 run fails any budget.
- Opt‑in telemetry pipelines p50/p95 latency to Grafana.
- Slack bot alerts if p95 blows budget twice in 24 h.

---

## 7 · Milestones & Sequencing _(placeholder)_

- Spike → Alpha → Beta → Launch; durations TBD with tech lead.

---

## 8 · Risks & Mitigation _(placeholder)_

- Parser accuracy on non‑English PDFs.
- Whisper license cost vs usage.
- Apple‑facing notarisation size limits.

---

## 9 · Appendices

### 9·1 Lo‑Fi Wireframes

#### Clip Modal

```
┌─────────────────────────────────────560 px────────────────────────────────────┐
│ ┌───────────────┐    ┌─────────────────────── OCR / TEXT ──────────────────┐  │
│ │  THUMBNAIL    │    │  “Explain this…” (pre-filled)                       │  │
│ │  screenshot   │    │                                                   ▼ │  │
│ └───────────────┘    │  Lorem ipsum dolor sit amet… (editable)             │  │
│                      └─────────────────────────────────────────────────────┘  │
│ ┌──────── CHECKLIST ───────┐                                                  │
│ │☑ Chapter 1               │                                                  │
│ │☐ Maps + Figures          │                                                  │
│ │☐ Questions               │                                                  │
│ └──────────────────────────┘                                                  │
│ ───────────────────────────────────────────────────────────────────────────── │
│  ⌂ Cancel           ↺ Ask-AI (⇧⌥ held)            Save & Link ⏎               │
└───────────────────────────────────────────────────────────────────────────────┘

```

#### Today’s Desk

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  📅 Thursday 25 Jun           Captures  ▂▅▆▂▁▇▂  (sparkline)                 │
├────────────── LIST (scroll) ────────────────┬────────  DETAILS  ─────────────┤
│  ⦿ 09:02  Voice note                        │   Transcript + AI summary     │
│  ○ 08:51  Clip: “Meso-trade map”            │                               │
│  ○ 08:35  Brainstorm (5 min)                │                               │
│  …                                          │   [Create task]  [Link]       │
│                                             │                               │
├──────────────────────────────────────────────┴──────────────────────────────┤
│  ⬑ Back to Packet                              New Capture  +               │
└──────────────────────────────────────────────────────────────────────────────┘

```

#### Brainstorm Overlay

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ✨ Brainstorm (local)   • Temp: 52 °C   • Model: Mistral-7B-Q4              │
│──────────────────────────────────────────────────────────────────────────────│
│                                                                              │
│                (faint canvas grid, full-screen for handwriting later)        │
│                                                                              │
│                                                      ┌───────────────────┐   │
│                                                      │   Live transcript │   │
│                                                      │   appears here…   │   │
│                                                      │                   │   │
│                                                      └───────────────────┘   │
│                                                                              │
│                                                                              │
│ ──────────────────────────────────────────────────────────────────────────── │
│   ■■■■▆▅▃▃▂▂▂  (waveform)                ●  STOP ⏎        ✖  DISCARD        │
└──────────────────────────────────────────────────────────────────────────────┘

```

#### Hotkey Cheatsheet Overlay

```
┌───────────────────────────────────── 420 px ─────────────────────────────────────┐
│  ⌨️  Workbench Shortcuts                          ✖  (Esc or click outside)      │
├───────────────────────────────────────────────────────────────────────────────────┤
│  📸  Capture                                                                     │
│   ⌘⇧C           Screen-clip + OCR/Ask-AI                                          │
│   ⌥ Space       Push-to-talk voice note (hold)                                    │
│   ⌘⇧B           Brainstorm canvas (toggle)                                        │
│                                                                                  │
│  🗂  Navigation                                                                   │
│   ⌘1            Today’s Desk                                                     │
│   ⌘2            Packet Dashboard                                                 │
│   ⌘`            Cycle open packets                                               │
│                                                                                  │
│  🤖  AI Actions                                                                  │
│   ⌥⇧ (hold)    Pre-fill “Explain this…” in clip modal                            │
│   ⌘↩           Re-ask AI with same context                                       │
│                                                                                  │
│  🔒  Privacy & Settings                                                          │
│   ⌥P            Toggle **Local-only** mode                                       │
│   ⌥⌘,           Preferences                                                      │
│                                                                                  │
│  🛑  System                                                                        │
│   ⌘Q            Quit Workbench                                                   │
│   ⌘⌥⇧⎋         Force restart local LLM                                           │
└───────────────────────────────────────────────────────────────────────────────────┘

```

### 9·2 Source Documents

- `PRD-v1.pdf` – original spec.
- `Q&A-log.pdf` – open decisions transcript.

---

## ✅ Next Steps Checklist

1. Plug any **TBD** numbers or owner names above.
2. Drop ASCII wireframes into Figma frames and start hi‑fi design.
3. Create engineering tickets for **Known Gaps** and **Perf QA** assets.
4. Schedule 30‑min walkthrough with Tech & Design to ratify budgets.
5. Scaffold packet‑import spike on branch `feat/initial‑skeleton`.

---

_End of PRD v2 draft_
