//
//  VoiceService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class VoiceService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentRecordingDuration: TimeInterval = 0
    @Published var lastTranscription: String = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var microphonePermission: Bool = false
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    override init() {
        super.init()
        setupSpeechRecognizer()
        checkPermissions()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    private func checkPermissions() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        // On macOS, we'll request microphone permission when needed
        microphonePermission = true
    }
    
    func requestPermissions() async -> Bool {
        // Request speech recognition permission
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: ())
                }
            }
        }
        
        // On macOS, microphone permission is handled by the system
        // We'll assume it's granted if we can access the audio engine
        microphonePermission = true
        
        return authorizationStatus == .authorized && microphonePermission
    }
    
    func startRecording() throws {
        guard !isRecording else { return }
        
        // Check permissions
        guard authorizationStatus == .authorized else {
            throw VoiceError.speechRecognitionNotAuthorized
        }
        
        guard microphonePermission else {
            throw VoiceError.microphoneNotAuthorized
        }
        
        // Stop any existing recording
        stopRecording()
        
        // On macOS, we don't need to configure audio session like on iOS
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw VoiceError.audioEngineInitializationFailed
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionRequestInitializationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.lastTranscription = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    print("Speech recognition error: \(error.localizedDescription)")
                    self?.stopRecording()
                }
            }
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Update state
        isRecording = true
        recordingStartTime = Date()
        lastTranscription = ""
        
        // Start timer for duration tracking
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateRecordingDuration()
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Stop recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Stop timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Clean up
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        // Update state
        isRecording = false
        currentRecordingDuration = 0
        recordingStartTime = nil
        
        // On macOS, no audio session to deactivate
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        currentRecordingDuration = Date().timeIntervalSince(startTime)
    }
    
    func createVoiceCapture(for packet: Packet, title: String? = nil) -> Capture {
        let capture = Capture(
            type: .voice,
            title: title ?? "Voice Note",
            content: lastTranscription
        )
        capture.duration = currentRecordingDuration
        capture.packet = packet
        return capture
    }
}

extension VoiceService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            Task { @MainActor in
                stopRecording()
            }
        }
    }
}

enum VoiceError: LocalizedError {
    case speechRecognitionNotAuthorized
    case microphoneNotAuthorized
    case audioEngineInitializationFailed
    case recognitionRequestInitializationFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .microphoneNotAuthorized:
            return "Microphone access not authorized. Please enable in Settings."
        case .audioEngineInitializationFailed:
            return "Failed to initialize audio engine."
        case .recognitionRequestInitializationFailed:
            return "Failed to initialize speech recognition request."
        case .recordingFailed:
            return "Recording failed. Please try again."
        }
    }
}