//
//  Capture.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import SwiftData

@Model
final class Capture {
    var id: UUID
    var type: CaptureType
    var title: String
    var content: String
    var transcript: String?
    var summary: String?
    var audioURL: URL?
    var imageURL: URL?
    var timestamp: Date
    var duration: TimeInterval?
    var confidence: Double?
    
    var packet: Packet?
    
    var linkedItems: [ChecklistItem] = []
    
    init(type: CaptureType, title: String = "", content: String = "") {
        self.id = UUID()
        self.type = type
        self.title = title.isEmpty ? type.defaultTitle : title
        self.content = content
        self.transcript = nil
        self.summary = nil
        self.audioURL = nil
        self.imageURL = nil
        self.timestamp = Date()
        self.duration = nil
        self.confidence = nil
        self.linkedItems = []
    }
    
    func addTranscript(_ transcript: String, confidence: Double? = nil) {
        self.transcript = transcript
        self.confidence = confidence
        if content.isEmpty {
            self.content = transcript
        }
        packet?.updateModifiedDate()
    }
    
    func addSummary(_ summary: String) {
        self.summary = summary
        packet?.updateModifiedDate()
    }
    
    func linkToItem(_ item: ChecklistItem) {
        if !linkedItems.contains(item) {
            linkedItems.append(item)
        }
        packet?.updateModifiedDate()
    }
    
    func unlinkFromItem(_ item: ChecklistItem) {
        linkedItems.removeAll { $0.id == item.id }
        packet?.updateModifiedDate()
    }
    
    var displayDuration: String {
        guard let duration = duration else { return "" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hasAudio: Bool {
        return audioURL != nil
    }
    
    var hasImage: Bool {
        return imageURL != nil
    }
}

enum CaptureType: String, CaseIterable, Codable {
    case voice = "voice"
    case screenClip = "screen_clip"
    case brainstorm = "brainstorm"
    case text = "text"
    case image = "image"
    
    var displayName: String {
        switch self {
        case .voice: return "Voice Note"
        case .screenClip: return "Screen Clip"
        case .brainstorm: return "Brainstorm"
        case .text: return "Text Note"
        case .image: return "Image"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .voice: return "mic.fill"
        case .screenClip: return "camera.viewfinder"
        case .brainstorm: return "brain.head.profile"
        case .text: return "text.alignleft"
        case .image: return "photo.fill"
        }
    }
    
    var defaultTitle: String {
        switch self {
        case .voice: return "Voice Note"
        case .screenClip: return "Screen Clip"
        case .brainstorm: return "Brainstorm Session"
        case .text: return "Text Note"
        case .image: return "Image"
        }
    }
}