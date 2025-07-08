//
//  ServiceContainer.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class ServiceContainer: ObservableObject {
    let dataService: DataService
    let pdfService: PDFService
    let voiceService: VoiceService
    let screenClipService: ScreenClipService
    let brainstormService: BrainstormService
    let hotkeyService: HotkeyService
    
    // Future services will be added here:
    // let aiService: AIService
    
    init(modelContext: ModelContext) {
        self.dataService = DataService(modelContext: modelContext)
        self.pdfService = PDFService(modelContext: modelContext)
        self.voiceService = VoiceService()
        self.screenClipService = ScreenClipService()
        self.brainstormService = BrainstormService()
        self.hotkeyService = HotkeyService()
        
        // Wire up services
        self.hotkeyService.voiceService = voiceService
        self.hotkeyService.screenClipService = screenClipService
        self.hotkeyService.brainstormService = brainstormService
    }
}

// Environment key for dependency injection
private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer? = nil
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}