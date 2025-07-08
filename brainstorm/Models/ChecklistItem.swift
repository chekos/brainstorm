//
//  ChecklistItem.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID
    var title: String
    var status: ItemStatus
    var pageReference: String?
    var notes: String?
    var reflection: String?
    var order: Int
    var createdAt: Date
    var modifiedAt: Date
    var completedAt: Date?
    
    var packet: Packet?
    
    @Relationship(deleteRule: .nullify)
    var captures: [Capture] = []
    
    init(title: String, pageReference: String? = nil, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.status = .pending
        self.pageReference = pageReference
        self.notes = nil
        self.reflection = nil
        self.order = order
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.completedAt = nil
        self.captures = []
    }
    
    func updateStatus(_ newStatus: ItemStatus) {
        self.status = newStatus
        self.modifiedAt = Date()
        
        if newStatus == .completed && completedAt == nil {
            self.completedAt = Date()
        } else if newStatus != .completed {
            self.completedAt = nil
        }
        
        packet?.updateModifiedDate()
    }
    
    func addNotes(_ newNotes: String) {
        self.notes = newNotes
        self.modifiedAt = Date()
        packet?.updateModifiedDate()
    }
    
    func addReflection(_ newReflection: String) {
        self.reflection = newReflection
        self.modifiedAt = Date()
        packet?.updateModifiedDate()
    }
    
    var displayProgress: String {
        guard let pageRef = pageReference else { return "" }
        return "p. \(pageRef)"
    }
}

enum ItemStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case blocked = "blocked"
    case skipped = "skipped"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .blocked: return "Blocked"
        case .skipped: return "Skipped"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .blocked: return "exclamationmark.triangle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}