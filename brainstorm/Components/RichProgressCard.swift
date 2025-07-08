//
//  RichProgressCard.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct RichProgressCard: View {
    let item: ChecklistItem
    let packet: Packet
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingAttachmentPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: onSelect) {
                cardContent
            }
            .buttonStyle(.plain)
            
            // Attachment/Action bar (only when selected)
            if isSelected {
                attachmentBar
            }
        }
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status and progress
            HStack(alignment: .top, spacing: 12) {
                // Status indicator
                statusIndicator
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata row
                    HStack {
                        if !item.displayProgress.isEmpty {
                            pageReference
                        }
                        
                        Spacer()
                        
                        if !item.captures.isEmpty {
                            captureIndicator
                        }
                        
                        statusBadge
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            // Progress preview (notes/reflection)
            if hasContent {
                contentPreview
            }
            
            // Completion info
            if let completedAt = item.completedAt {
                completionInfo(completedAt)
            }
        }
        .padding(16)
    }
    
    private var statusIndicator: some View {
        Button(action: toggleStatus) {
            ZStack {
                Circle()
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if item.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(statusColor)
                } else if item.status == .inProgress {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var pageReference: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.pages")
                .font(.caption2)
            Text(formatPageReference())
                .font(.caption)
        }
        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
    }
    
    private var captureIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "link")
                .font(.caption2)
            Text("\(item.captures.count)")
                .font(.caption)
        }
        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
    }
    
    private var statusBadge: some View {
        Text(item.status.displayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(isSelected ? 0.3 : 0.15))
            .foregroundColor(isSelected ? .white : statusColor)
            .cornerRadius(12)
    }
    
    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            if let reflection = item.reflection, !reflection.isEmpty {
                Label {
                    Text(reflection)
                        .font(.caption)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "lightbulb.min")
                        .font(.caption2)
                }
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
        }
        .padding(.top, 4)
    }
    
    private func completionInfo(_ date: Date) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
            
            Text("Completed \(date, style: .relative)")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private var attachmentBar: some View {
        HStack(spacing: 12) {
            // Add screenshot button
            Button(action: { showingAttachmentPicker = true }) {
                Label("Add Screenshot", systemImage: "camera.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Quick action buttons
            Button(action: { /* TODO: AI Summary */ }) {
                Image(systemName: "sparkles")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(true) // TODO: Enable when AI integration is ready
            
            Button(action: { /* TODO: Add Note */ }) {
                Image(systemName: "note.text.badge.plus")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color(NSColor.controlBackgroundColor)))
    }
    
    private var statusColor: Color {
        switch item.status {
        case .pending: return .secondary
        case .inProgress: return .orange
        case .completed: return .green
        case .blocked: return .red
        case .skipped: return .gray
        }
    }
    
    private var hasContent: Bool {
        (item.notes?.isEmpty == false) || (item.reflection?.isEmpty == false)
    }
    
    private func formatPageReference() -> String {
        guard let pageRef = item.pageReference else { return "" }
        
        // If packet has sections, try to show "p. X of Y" format
        if !packet.sections.isEmpty {
            // Try to extract total pages from sections
            let pageNumbers = packet.sections.compactMap { section in
                section.pageReference?.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap(Int.init)
                    .max()
            }
            
            if let maxPage = pageNumbers.max() {
                return "p. \(pageRef) of \(maxPage)"
            }
        }
        
        return "p. \(pageRef)"
    }
    
    private func toggleStatus() {
        let newStatus: ItemStatus
        switch item.status {
        case .pending: newStatus = .inProgress
        case .inProgress: newStatus = .completed
        case .completed: newStatus = .pending
        case .blocked: newStatus = .inProgress
        case .skipped: newStatus = .pending
        }
        
        item.updateStatus(newStatus)
        try? modelContext.save()
    }
}

#Preview {
    let item = ChecklistItem(title: "Review Chapter 3: Advanced SwiftUI Patterns", pageReference: "45", order: 0)
    item.addNotes("Key concepts include state management and custom view modifiers")
    item.addReflection("This chapter really helped clarify how to structure complex views")
    
    let packet = Packet(title: "SwiftUI Mastery")
    
    return VStack(spacing: 16) {
        RichProgressCard(
            item: item,
            packet: packet,
            isSelected: false,
            onSelect: {}
        )
        
        RichProgressCard(
            item: item,
            packet: packet,
            isSelected: true,
            onSelect: {}
        )
    }
    .padding()
    .modelContainer(for: [Packet.self, ChecklistItem.self, Capture.self], inMemory: true)
}