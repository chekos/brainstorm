//
//  Packet.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData

@Model
final class Packet {
    var id: UUID
    var title: String
    var sourceURL: URL?
    var originalFilename: String?
    var createdAt: Date
    var modifiedAt: Date
    var isArchived: Bool
    
    @Relationship(deleteRule: .cascade)
    var sections: [PacketSection] = []
    
    @Relationship(deleteRule: .cascade)
    var checklistItems: [ChecklistItem] = []
    
    @Relationship(deleteRule: .cascade)
    var captures: [Capture] = []
    
    init(title: String, sourceURL: URL? = nil, originalFilename: String? = nil) {
        self.id = UUID()
        self.title = title
        self.sourceURL = sourceURL
        self.originalFilename = originalFilename
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isArchived = false
        self.sections = []
        self.checklistItems = []
        self.captures = []
    }
    
    func updateModifiedDate() {
        self.modifiedAt = Date()
    }
    
    var progress: Double {
        guard !checklistItems.isEmpty else { return 0.0 }
        let completedCount = checklistItems.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(checklistItems.count)
    }
    
    var isCompleted: Bool {
        !checklistItems.isEmpty && checklistItems.allSatisfy { $0.status == .completed }
    }
}