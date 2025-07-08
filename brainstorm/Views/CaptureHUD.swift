//
//  CaptureHUD.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct CaptureHUD: View {
    @ObservedObject var voiceService: VoiceService
    @ObservedObject var screenClipService: ScreenClipService
    @ObservedObject var brainstormService: BrainstormService
    @ObservedObject var hotkeyService: HotkeyService
    
    @State private var showingVoicePermissionAlert = false
    @State private var showingLinkingSheet = false
    @State private var selectedCapture: Capture?
    @State private var availablePackets: [Packet] = []
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Voice Capture Section
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Voice Notes")
                            .font(.headline)
                        
                        Text("⌥Space to record")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Toggle("", isOn: $hotkeyService.isVoiceHotkeyEnabled)
                            .labelsHidden()
                            .onChange(of: hotkeyService.isVoiceHotkeyEnabled) { _, enabled in
                                if enabled {
                                    Task {
                                        let hasPermission = await voiceService.requestPermissions()
                                        if hasPermission {
                                            hotkeyService.registerVoiceHotkey()
                                        } else {
                                            showingVoicePermissionAlert = true
                                            hotkeyService.isVoiceHotkeyEnabled = false
                                        }
                                    }
                                } else {
                                    hotkeyService.unregisterVoiceHotkey()
                                }
                            }
                    }
                }
                
                if voiceService.isRecording {
                    VoiceRecordingView(
                        transcription: voiceService.lastTranscription,
                        duration: voiceService.currentRecordingDuration,
                        onStop: {
                            voiceService.stopRecording()
                        },
                        onSave: { packet in
                            let capture = voiceService.createVoiceCapture(for: packet)
                            modelContext.insert(capture)
                            try? modelContext.save()
                        }
                    )
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Screen Clip Section
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Screen Clips")
                            .font(.headline)
                        
                        Text("⌘⇧C to capture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hotkeyService.isScreenClipHotkeyEnabled)
                        .labelsHidden()
                        .onChange(of: hotkeyService.isScreenClipHotkeyEnabled) { _, enabled in
                            if enabled {
                                hotkeyService.registerScreenClipHotkey()
                            } else {
                                hotkeyService.unregisterScreenClipHotkey()
                            }
                        }
                }
                
                if screenClipService.isClipping {
                    Text("Select area to capture...")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                if let clipImage = screenClipService.lastClipImage {
                    ScreenClipResultView(
                        image: clipImage,
                        ocrText: screenClipService.lastOCRText,
                        onSave: { packet in
                            let capture = screenClipService.createScreenClipCapture(for: packet)
                            modelContext.insert(capture)
                            try? modelContext.save()
                        }
                    )
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Brainstorm Section
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Brainstorm Mode")
                            .font(.headline)
                        
                        Text("⌘⇧B to toggle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hotkeyService.isBrainstormHotkeyEnabled)
                        .labelsHidden()
                        .onChange(of: hotkeyService.isBrainstormHotkeyEnabled) { _, enabled in
                            if enabled {
                                hotkeyService.registerBrainstormHotkey()
                            } else {
                                hotkeyService.unregisterBrainstormHotkey()
                            }
                        }
                }
                
                if brainstormService.isActive {
                    Text("Brainstorm session active")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
                
                if !brainstormService.lastCapturedThought.isEmpty {
                    BrainstormResultView(
                        thought: brainstormService.lastCapturedThought,
                        sessionDuration: brainstormService.sessionDuration,
                        onSave: { packet in
                            let capture = brainstormService.createBrainstormCapture(for: packet)
                            modelContext.insert(capture)
                            try? modelContext.save()
                        }
                    )
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Status
            HStack {
                Text("Press hotkeys to capture content")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 600)
        .alert("Permissions Required", isPresented: $showingVoicePermissionAlert) {
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Voice notes require microphone and speech recognition permissions. Please enable them in System Settings.")
        }
        .onAppear {
            hotkeyService.voiceService = voiceService
            hotkeyService.screenClipService = screenClipService
            hotkeyService.brainstormService = brainstormService
        }
    }
}

struct VoiceRecordingView: View {
    let transcription: String
    let duration: TimeInterval
    let onStop: () -> Void
    let onSave: (Packet) -> Void
    
    @State private var showingPacketSelector = false
    @State private var availablePackets: [Packet] = []
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.2)
                    .opacity(0.8)
                
                Text("Recording")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text(formatDuration(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                Text(transcription.isEmpty ? "Start speaking..." : transcription)
                    .font(.caption)
                    .foregroundColor(transcription.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .frame(height: 60)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            
            HStack {
                Button("Stop") {
                    onStop()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if !transcription.isEmpty {
                    Button("Save") {
                        showingPacketSelector = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingPacketSelector) {
            PacketSelectorView(availablePackets: availablePackets) { packet in
                onSave(packet)
            }
        }
        .onAppear {
            loadAvailablePackets()
        }
    }
    
    private func loadAvailablePackets() {
        let descriptor = FetchDescriptor<Packet>()
        availablePackets = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ScreenClipResultView: View {
    let image: NSImage
    let ocrText: String
    let onSave: (Packet) -> Void
    
    @State private var showingPacketSelector = false
    @State private var availablePackets: [Packet] = []
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Screen captured")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 60)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("OCR Text:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(ocrText.isEmpty ? "No text detected" : ocrText)
                            .font(.caption)
                            .foregroundColor(ocrText.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(height: 40)
                }
            }
            
            HStack {
                Spacer()
                
                Button("Save") {
                    showingPacketSelector = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingPacketSelector) {
            PacketSelectorView(availablePackets: availablePackets) { packet in
                onSave(packet)
            }
        }
        .onAppear {
            loadAvailablePackets()
        }
    }
    
    private func loadAvailablePackets() {
        let descriptor = FetchDescriptor<Packet>()
        availablePackets = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct BrainstormResultView: View {
    let thought: String
    let sessionDuration: TimeInterval
    let onSave: (Packet) -> Void
    
    @State private var showingPacketSelector = false
    @State private var availablePackets: [Packet] = []
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                Text("Thought captured")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(formatDuration(sessionDuration))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                Text(thought)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .frame(height: 60)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            
            HStack {
                Spacer()
                
                Button("Save") {
                    showingPacketSelector = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingPacketSelector) {
            PacketSelectorView(availablePackets: availablePackets) { packet in
                onSave(packet)
            }
        }
        .onAppear {
            loadAvailablePackets()
        }
    }
    
    private func loadAvailablePackets() {
        let descriptor = FetchDescriptor<Packet>()
        availablePackets = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PacketSelectorView: View {
    let availablePackets: [Packet]
    let onSelect: (Packet) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(availablePackets) { packet in
                Button(action: {
                    onSelect(packet)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(packet.title)
                                .font(.headline)
                            
                            if !packet.checklistItems.isEmpty {
                                Text("\(packet.checklistItems.count) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Packet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

#Preview {
    CaptureHUD(
        voiceService: VoiceService(),
        screenClipService: ScreenClipService(),
        brainstormService: BrainstormService(),
        hotkeyService: HotkeyService()
    )
    .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}