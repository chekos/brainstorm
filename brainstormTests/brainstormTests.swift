//
//  brainstormTests.swift
//  brainstormTests
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Testing
@testable import brainstorm
import SwiftData

struct brainstormTests {

    @MainActor @Test func testServiceContainerInitialization() throws {
        // Create in-memory model container for testing
        let schema = Schema([Packet.self, PacketSection.self, ChecklistItem.self, Capture.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        
        // Test service container initialization
        let serviceContainer = ServiceContainer(modelContext: context)
        
        // Verify all services are initialized
        #expect(serviceContainer.voiceService != nil)
        #expect(serviceContainer.screenClipService != nil)
        #expect(serviceContainer.brainstormService != nil)
        #expect(serviceContainer.hotkeyService != nil)
        #expect(serviceContainer.pdfService != nil)
        #expect(serviceContainer.dataService != nil)
    }
    
    @Test func testPacketCreation() throws {
        // Test packet model creation
        let packet = Packet(title: "Test Packet", sourceURL: nil)
        
        #expect(packet.title == "Test Packet")
        #expect(packet.sourceURL == nil)
        #expect(packet.sections.isEmpty)
        #expect(packet.checklistItems.isEmpty)
        #expect(packet.captures.isEmpty)
        #expect(packet.isArchived == false)
    }

    @Test func testCaptureCreation() throws {
        // Test capture model creation
        let capture = Capture(type: .voice, title: "Test Voice Note", content: "Test transcription")
        
        #expect(capture.type == .voice)
        #expect(capture.title == "Test Voice Note")
        #expect(capture.content == "Test transcription")
        #expect(capture.packet == nil)
    }

}
