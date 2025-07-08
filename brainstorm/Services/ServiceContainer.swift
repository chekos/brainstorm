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
    let aiService: AIServiceRouter
    
    init(modelContext: ModelContext) {
        self.dataService = DataService(modelContext: modelContext)
        self.aiService = AIServiceRouter()
        self.pdfService = PDFService(modelContext: modelContext)
        self.voiceService = VoiceService()
        self.screenClipService = ScreenClipService()
        self.brainstormService = BrainstormService()
        self.hotkeyService = HotkeyService()
        
        // Wire up services directly - we're already on MainActor
        self.hotkeyService.voiceService = self.voiceService
        self.hotkeyService.screenClipService = self.screenClipService
        self.hotkeyService.brainstormService = self.brainstormService
    }
    
    deinit {
        // Clean up services when container is deallocated
        // Note: deinit runs on whatever thread the object is being deallocated on
        // Since HotkeyService is @MainActor, we need to be careful about cleanup
        Task { @MainActor in
            hotkeyService.voiceService = nil
            hotkeyService.screenClipService = nil
            hotkeyService.brainstormService = nil
        }
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