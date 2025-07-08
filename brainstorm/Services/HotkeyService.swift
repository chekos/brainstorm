//
//  HotkeyService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyService: ObservableObject {
    @Published var isVoiceHotkeyEnabled = false
    @Published var isScreenClipHotkeyEnabled = false
    @Published var isBrainstormHotkeyEnabled = false
    
    private var voiceHotkeyRef: EventHotKeyRef?
    private var screenClipHotkeyRef: EventHotKeyRef?
    private var brainstormHotkeyRef: EventHotKeyRef?
    
    private var eventHandlerRef: EventHandlerRef?
    
    weak var voiceService: VoiceService?
    weak var screenClipService: ScreenClipService?
    weak var brainstormService: BrainstormService?
    
    init() {
        setupEventHandler()
    }
    
    deinit {
        // deinit is called synchronously, so we need to clean up synchronously
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        
        // Clean up hotkeys synchronously
        if let hotkeyRef = voiceHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
        if let hotkeyRef = screenClipHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
        if let hotkeyRef = brainstormHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
    }
    
    private func setupEventHandler() {
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let eventSpecs = [eventSpec]
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let hotkeyService = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                
                var hotkeyID = EventHotKeyID()
                GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
                
                Task { @MainActor in
                    hotkeyService.handleHotkey(id: hotkeyID.id)
                }
                
                return OSStatus(noErr)
            },
            1,
            eventSpecs,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }
    
    private func handleHotkey(id: UInt32) {
        switch id {
        case 1: // Voice hotkey (⌥Space)
            handleVoiceHotkey()
        case 2: // Screen clip hotkey (⌘⇧C)
            handleScreenClipHotkey()
        case 3: // Brainstorm hotkey (⌘⇧B)
            handleBrainstormHotkey()
        default:
            break
        }
    }
    
    private func handleVoiceHotkey() {
        guard let voiceService = voiceService else { return }
        
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            do {
                try voiceService.startRecording()
            } catch {
                print("Failed to start voice recording: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleScreenClipHotkey() {
        guard let screenClipService = screenClipService else { return }
        screenClipService.startScreenClipping()
    }
    
    private func handleBrainstormHotkey() {
        guard let brainstormService = brainstormService else { return }
        brainstormService.toggleBrainstormMode()
    }
    
    func registerVoiceHotkey() {
        guard voiceHotkeyRef == nil else { return }
        
        let hotkeyID = EventHotKeyID(signature: OSType(0x56435348), id: 1) // 'VCSH' for Voice Capture Shortcut Hotkey
        
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &voiceHotkeyRef
        )
        
        isVoiceHotkeyEnabled = true
    }
    
    func unregisterVoiceHotkey() {
        if let hotkeyRef = voiceHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            voiceHotkeyRef = nil
        }
        isVoiceHotkeyEnabled = false
    }
    
    func registerScreenClipHotkey() {
        guard screenClipHotkeyRef == nil else { return }
        
        let hotkeyID = EventHotKeyID(signature: OSType(0x53435348), id: 2) // 'SCSH' for Screen Clip Shortcut Hotkey
        
        RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(cmdKey | shiftKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &screenClipHotkeyRef
        )
        
        isScreenClipHotkeyEnabled = true
    }
    
    func unregisterScreenClipHotkey() {
        if let hotkeyRef = screenClipHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            screenClipHotkeyRef = nil
        }
        isScreenClipHotkeyEnabled = false
    }
    
    func registerBrainstormHotkey() {
        guard brainstormHotkeyRef == nil else { return }
        
        let hotkeyID = EventHotKeyID(signature: OSType(0x42535348), id: 3) // 'BSSH' for Brainstorm Shortcut Hotkey
        
        RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(cmdKey | shiftKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &brainstormHotkeyRef
        )
        
        isBrainstormHotkeyEnabled = true
    }
    
    func unregisterBrainstormHotkey() {
        if let hotkeyRef = brainstormHotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            brainstormHotkeyRef = nil
        }
        isBrainstormHotkeyEnabled = false
    }
    
    func registerAllHotkeys() {
        registerVoiceHotkey()
        registerScreenClipHotkey()
        registerBrainstormHotkey()
    }
    
    func unregisterAllHotkeys() {
        unregisterVoiceHotkey()
        unregisterScreenClipHotkey()
        unregisterBrainstormHotkey()
    }
}