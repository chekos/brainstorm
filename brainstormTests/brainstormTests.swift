//
//  brainstormTests.swift
//  brainstormTests
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Testing
@testable import brainstorm
import SwiftData
import Foundation

@MainActor
struct brainstormTests {

    @Test func testBasicCreation() throws {
        // Very simple test - just create objects and verify basic properties
        let packet = Packet(title: "Test Packet")
        #expect(packet.title == "Test Packet")
        
        let capture = Capture(type: .voice)
        #expect(capture.type == .voice)
        
        let item = ChecklistItem(title: "Test Item")
        #expect(item.title == "Test Item")
        
        let section = PacketSection(title: "Test Section", content: "Test content")
        #expect(section.title == "Test Section")
    }
    
    @Test func testCaptureTypes() throws {
        // Test capture type enums
        #expect(CaptureType.voice.displayName == "Voice Note")
        #expect(CaptureType.screenClip.displayName == "Screen Clip")
        #expect(CaptureType.brainstorm.displayName == "Brainstorm")
        
        #expect(CaptureType.voice.systemImageName == "mic.fill")
        #expect(CaptureType.screenClip.systemImageName == "camera.viewfinder")
    }
    
    @Test func testItemStatus() throws {
        // Test item status enums
        #expect(ItemStatus.pending.displayName == "Pending")
        #expect(ItemStatus.inProgress.displayName == "In Progress")
        #expect(ItemStatus.completed.displayName == "Completed")
        
        #expect(ItemStatus.pending.systemImageName == "circle")
        #expect(ItemStatus.completed.systemImageName == "checkmark.circle.fill")
    }
    
    @Test func testSectionTypes() throws {
        // Test section type enums
        #expect(SectionType.heading.displayName == "Heading")
        #expect(SectionType.content.displayName == "Content")
        #expect(SectionType.task.displayName == "Task")
    }
    
    @Test func testPacketProperties() throws {
        // Test packet with more detailed properties
        let packet = Packet(title: "Complex Packet", sourceURL: URL(string: "file://test.pdf"))
        
        #expect(packet.title == "Complex Packet")
        #expect(packet.sourceURL?.absoluteString == "file://test.pdf")
        #expect(packet.sections.isEmpty)
        #expect(packet.checklistItems.isEmpty)
        #expect(packet.captures.isEmpty)
        #expect(packet.isArchived == false)
        #expect(packet.progress == 0.0)
        
        // Test packet without URL
        let simplePacket = Packet(title: "Simple Packet")
        #expect(simplePacket.sourceURL == nil)
    }
    
    @Test func testCaptureWithContent() throws {
        // Test capture creation with various content
        let voiceNote = Capture(type: .voice, title: "Meeting Notes", content: "Discussed project timeline")
        
        #expect(voiceNote.type == .voice)
        #expect(voiceNote.title == "Meeting Notes")
        #expect(voiceNote.content == "Discussed project timeline")
        #expect(voiceNote.transcript == nil)
        #expect(voiceNote.duration == nil)
        #expect(voiceNote.linkedItems.isEmpty)
        
        // Test capture with empty title gets default
        let screenClip = Capture(type: .screenClip, title: "", content: "Screenshot text")
        #expect(screenClip.title == "Screen Clip") // Should use default title
    }
    
    @Test func testChecklistItemCreation() throws {
        // Test checklist item with page reference
        let item = ChecklistItem(title: "Review Chapter 3", pageReference: "45", order: 1)
        
        #expect(item.title == "Review Chapter 3")
        #expect(item.pageReference == "45")
        #expect(item.order == 1)
        #expect(item.status == .pending)
        #expect(item.notes == nil)
        #expect(item.reflection == nil)
        #expect(item.completedAt == nil)
        #expect(item.displayProgress == "p. 45")
        
        // Test item without page reference
        let simpleItem = ChecklistItem(title: "Simple Task")
        #expect(simpleItem.displayProgress == "")
    }
    
    @Test func testServiceContainerInitialization() throws {
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
        
        // Verify service wiring
        #expect(serviceContainer.hotkeyService.voiceService === serviceContainer.voiceService)
        #expect(serviceContainer.hotkeyService.screenClipService === serviceContainer.screenClipService)
        #expect(serviceContainer.hotkeyService.brainstormService === serviceContainer.brainstormService)
    }
}
