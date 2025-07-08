//
//  PacketSection.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData

@Model
final class PacketSection {
    var id: UUID
    var title: String
    var content: String
    var pageReference: String?
    var sectionType: SectionType
    var order: Int
    var createdAt: Date
    
    var packet: Packet?
    
    init(title: String, content: String, pageReference: String? = nil, sectionType: SectionType = .content, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.pageReference = pageReference
        self.sectionType = sectionType
        self.order = order
        self.createdAt = Date()
    }
}

enum SectionType: String, CaseIterable, Codable {
    case heading = "heading"
    case content = "content"
    case figure = "figure"
    case code = "code"
    case quote = "quote"
    case list = "list"
    case task = "task"
    
    var displayName: String {
        switch self {
        case .heading: return "Heading"
        case .content: return "Content"
        case .figure: return "Figure"
        case .code: return "Code"
        case .quote: return "Quote"
        case .list: return "List"
        case .task: return "Task"
        }
    }
}