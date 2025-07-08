//
//  DataService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData

@MainActor
class DataService: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Packet Operations
    
    func createPacket(title: String, sourceURL: URL? = nil, originalFilename: String? = nil) -> Packet {
        let packet = Packet(title: title, sourceURL: sourceURL, originalFilename: originalFilename)
        modelContext.insert(packet)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save packet: \(error)")
        }
        
        return packet
    }
    
    func deletePacket(_ packet: Packet) {
        modelContext.delete(packet)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete packet: \(error)")
        }
    }
    
    func archivePacket(_ packet: Packet) {
        packet.isArchived = true
        packet.updateModifiedDate()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to archive packet: \(error)")
        }
    }
    
    func unarchivePacket(_ packet: Packet) {
        packet.isArchived = false
        packet.updateModifiedDate()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to unarchive packet: \(error)")
        }
    }
    
    // MARK: - Checklist Item Operations
    
    func createChecklistItem(for packet: Packet, title: String, pageReference: String? = nil) -> ChecklistItem {
        let item = ChecklistItem(
            title: title,
            pageReference: pageReference,
            order: packet.checklistItems.count
        )
        item.packet = packet
        modelContext.insert(item)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save checklist item: \(error)")
        }
        
        return item
    }
    
    func updateChecklistItemStatus(_ item: ChecklistItem, status: ItemStatus) {
        item.updateStatus(status)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update checklist item status: \(error)")
        }
    }
    
    func deleteChecklistItem(_ item: ChecklistItem) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete checklist item: \(error)")
        }
    }
    
    // MARK: - Capture Operations
    
    func createCapture(for packet: Packet, type: CaptureType, title: String = "", content: String = "") -> Capture {
        let capture = Capture(type: type, title: title, content: content)
        capture.packet = packet
        modelContext.insert(capture)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save capture: \(error)")
        }
        
        return capture
    }
    
    func linkCaptureToItem(_ capture: Capture, item: ChecklistItem) {
        capture.linkToItem(item)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to link capture to item: \(error)")
        }
    }
    
    func unlinkCaptureFromItem(_ capture: Capture, item: ChecklistItem) {
        capture.unlinkFromItem(item)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to unlink capture from item: \(error)")
        }
    }
    
    func deleteCapture(_ capture: Capture) {
        modelContext.delete(capture)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete capture: \(error)")
        }
    }
    
    // MARK: - Query Operations
    
    func getRecentCaptures(limit: Int = 50) -> [Capture] {
        let descriptor = FetchDescriptor<Capture>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let captures = try modelContext.fetch(descriptor)
            return Array(captures.prefix(limit))
        } catch {
            print("Failed to fetch recent captures: \(error)")
            return []
        }
    }
    
    func getCapturesForToday() -> [Capture] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<Capture> { capture in
            capture.timestamp >= today && capture.timestamp < tomorrow
        }
        
        let descriptor = FetchDescriptor<Capture>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch today's captures: \(error)")
            return []
        }
    }
    
    func getActivePackets() -> [Packet] {
        let predicate = #Predicate<Packet> { packet in
            !packet.isArchived
        }
        
        let descriptor = FetchDescriptor<Packet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch active packets: \(error)")
            return []
        }
    }
    
    func getArchivedPackets() -> [Packet] {
        let predicate = #Predicate<Packet> { packet in
            packet.isArchived
        }
        
        let descriptor = FetchDescriptor<Packet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch archived packets: \(error)")
            return []
        }
    }
}