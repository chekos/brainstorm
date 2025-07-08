//
//  BrainstormService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import AppKit
import Speech
import AVFoundation

@MainActor
class BrainstormService: ObservableObject {
    @Published var isActive = false
    @Published var currentTranscript: String = ""
    @Published var sessionDuration: TimeInterval = 0
    @Published var lastCapturedThought: String = ""
    
    private var overlayWindow: NSWindow?
    private var overlayView: BrainstormOverlayView?
    private var voiceService: VoiceService?
    private var sessionStartTime: Date?
    private var updateTimer: Timer?
    
    func toggleBrainstormMode() {
        if isActive {
            stopBrainstormMode()
        } else {
            startBrainstormMode()
        }
    }
    
    func startBrainstormMode() {
        guard !isActive else { return }
        
        isActive = true
        sessionStartTime = Date()
        currentTranscript = ""
        lastCapturedThought = ""
        
        setupVoiceService()
        showOverlay()
        startContinuousListening()
        startUpdateTimer()
    }
    
    func stopBrainstormMode() {
        guard isActive else { return }
        
        isActive = false
        hideOverlay()
        stopContinuousListening()
        stopUpdateTimer()
        
        sessionStartTime = nil
        sessionDuration = 0
    }
    
    private func setupVoiceService() {
        voiceService = VoiceService()
        
        // Request permissions if needed
        Task {
            await voiceService?.requestPermissions()
        }
    }
    
    private func showOverlay() {
        guard let mainScreen = NSScreen.main else { return }
        
        let overlayView = BrainstormOverlayView()
        overlayView.onCaptureThought = { [weak self] in
            self?.captureCurrentThought()
        }
        overlayView.onToggleListening = { [weak self] in
            self?.toggleListening()
        }
        overlayView.onEndSession = { [weak self] in
            self?.stopBrainstormMode()
        }
        
        let windowFrame = NSRect(
            x: mainScreen.frame.width - 400,
            y: mainScreen.frame.height - 250,
            width: 380,
            height: 200
        )
        
        overlayWindow = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.contentView = overlayView
        overlayWindow?.level = .floating
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor.clear
        overlayWindow?.ignoresMouseEvents = false
        overlayWindow?.makeKeyAndOrderFront(nil)
        
        self.overlayView = overlayView
    }
    
    private func hideOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        overlayView = nil
    }
    
    private func startContinuousListening() {
        guard let voiceService = voiceService else { return }
        
        do {
            try voiceService.startRecording()
        } catch {
            print("Failed to start continuous listening: \(error.localizedDescription)")
        }
    }
    
    private func stopContinuousListening() {
        voiceService?.stopRecording()
    }
    
    private func toggleListening() {
        guard let voiceService = voiceService else { return }
        
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            do {
                try voiceService.startRecording()
            } catch {
                print("Failed to toggle listening: \(error.localizedDescription)")
            }
        }
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSession()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateSession() {
        guard let startTime = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(startTime)
        
        // Update transcript from voice service
        if let transcript = voiceService?.lastTranscription {
            currentTranscript = transcript
        }
        
        // Update overlay
        overlayView?.updateContent(
            transcript: currentTranscript,
            duration: sessionDuration,
            isListening: voiceService?.isRecording ?? false
        )
    }
    
    private func captureCurrentThought() {
        guard !currentTranscript.isEmpty else { return }
        
        lastCapturedThought = currentTranscript
        
        // Clear current transcript for next thought
        currentTranscript = ""
        voiceService?.lastTranscription = ""
        
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )
    }
    
    func createBrainstormCapture(for packet: Packet, title: String? = nil) -> Capture {
        let capture = Capture(
            type: .brainstorm,
            title: title ?? "Brainstorm Session",
            content: lastCapturedThought
        )
        capture.duration = sessionDuration
        capture.packet = packet
        return capture
    }
}

class BrainstormOverlayView: NSView {
    private let backgroundMaterial = NSVisualEffectView()
    private let titleLabel = NSTextField()
    private let transcriptLabel = NSTextField()
    private let durationLabel = NSTextField()
    private let listeningIndicator = NSView()
    private let captureButton = NSButton()
    private let toggleButton = NSButton()
    private let endButton = NSButton()
    
    var onCaptureThought: (() -> Void)?
    var onToggleListening: (() -> Void)?
    var onEndSession: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Background
        backgroundMaterial.material = .hudWindow
        backgroundMaterial.blendingMode = .behindWindow
        backgroundMaterial.state = .active
        backgroundMaterial.wantsLayer = true
        backgroundMaterial.layer?.cornerRadius = 12
        addSubview(backgroundMaterial)
        
        // Title
        titleLabel.stringValue = "Brainstorm Mode"
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .labelColor
        titleLabel.isBordered = false
        titleLabel.isEditable = false
        titleLabel.backgroundColor = .clear
        addSubview(titleLabel)
        
        // Transcript
        transcriptLabel.stringValue = "Start speaking..."
        transcriptLabel.font = NSFont.systemFont(ofSize: 12)
        transcriptLabel.textColor = .secondaryLabelColor
        transcriptLabel.isBordered = false
        transcriptLabel.isEditable = false
        transcriptLabel.backgroundColor = .clear
        transcriptLabel.maximumNumberOfLines = 3
        transcriptLabel.lineBreakMode = .byTruncatingTail
        addSubview(transcriptLabel)
        
        // Duration
        durationLabel.stringValue = "00:00"
        durationLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = .tertiaryLabelColor
        durationLabel.isBordered = false
        durationLabel.isEditable = false
        durationLabel.backgroundColor = .clear
        addSubview(durationLabel)
        
        // Listening indicator
        listeningIndicator.wantsLayer = true
        listeningIndicator.layer?.backgroundColor = NSColor.systemRed.cgColor
        listeningIndicator.layer?.cornerRadius = 4
        addSubview(listeningIndicator)
        
        // Buttons
        captureButton.title = "Capture"
        captureButton.bezelStyle = .rounded
        captureButton.target = self
        captureButton.action = #selector(captureButtonTapped)
        addSubview(captureButton)
        
        toggleButton.title = "Pause"
        toggleButton.bezelStyle = .rounded
        toggleButton.target = self
        toggleButton.action = #selector(toggleButtonTapped)
        addSubview(toggleButton)
        
        endButton.title = "End"
        endButton.bezelStyle = .rounded
        endButton.target = self
        endButton.action = #selector(endButtonTapped)
        addSubview(endButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        [backgroundMaterial, titleLabel, transcriptLabel, durationLabel, listeningIndicator, captureButton, toggleButton, endButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Background
            backgroundMaterial.topAnchor.constraint(equalTo: topAnchor),
            backgroundMaterial.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundMaterial.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundMaterial.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Duration
            durationLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Listening indicator
            listeningIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            listeningIndicator.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            listeningIndicator.widthAnchor.constraint(equalToConstant: 8),
            listeningIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Transcript
            transcriptLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            transcriptLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            transcriptLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            transcriptLabel.heightAnchor.constraint(equalToConstant: 60),
            
            // Buttons
            captureButton.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: 12),
            captureButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            captureButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            toggleButton.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: 12),
            toggleButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            endButton.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: 12),
            endButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            endButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func captureButtonTapped() {
        onCaptureThought?()
    }
    
    @objc private func toggleButtonTapped() {
        onToggleListening?()
    }
    
    @objc private func endButtonTapped() {
        onEndSession?()
    }
    
    func updateContent(transcript: String, duration: TimeInterval, isListening: Bool) {
        transcriptLabel.stringValue = transcript.isEmpty ? "Start speaking..." : transcript
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        durationLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)
        
        listeningIndicator.isHidden = !isListening
        toggleButton.title = isListening ? "Pause" : "Resume"
        captureButton.isEnabled = !transcript.isEmpty
        
        if isListening {
            // Animate listening indicator
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                listeningIndicator.alphaValue = 0.3
            } completionHandler: {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    context.allowsImplicitAnimation = true
                    self.listeningIndicator.alphaValue = 1.0
                }
            }
        }
    }
}