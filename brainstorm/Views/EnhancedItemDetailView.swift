//
//  EnhancedItemDetailView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct EnhancedItemDetailView: View {
    let item: ChecklistItem
    let packet: Packet
    
    @Environment(\.modelContext) private var modelContext
    @State private var notes: String = ""
    @State private var reflection: String = ""
    @State private var isEditingNotes = false
    @State private var isEditingReflection = false
    @State private var showingAttachmentPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                headerSection
                
                // Status and progress section
                statusSection
                
                // Content sections
                contentSections
                
                // Linked captures section
                if !item.captures.isEmpty {
                    capturesSection
                }
                
                // Quick actions
                quickActionsSection
                
                Spacer()
            }
            .padding(24)
        }
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            notes = item.notes ?? ""
            reflection = item.reflection ?? ""
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and page reference
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    if !item.displayProgress.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "book.pages.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatPageReference())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Large status indicator
                statusIndicator
            }
            
            // Timestamps
            HStack(spacing: 16) {
                Label {
                    Text("Created \(item.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "plus.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if item.modifiedAt != item.createdAt {
                    Label {
                        Text("Updated \(item.modifiedAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "pencil.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let completedAt = item.completedAt {
                    Label {
                        Text("Completed \(completedAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.green)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Status")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    ForEach(ItemStatus.allCases, id: \.self) { status in
                        Button(action: { updateStatus(status) }) {
                            Label(status.displayName, systemImage: status.systemImageName)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.status.systemImageName)
                        Text(item.status.displayName)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            
            // Status-specific content
            if item.status == .blocked {
                Text("This item is blocked. Consider what's preventing progress and update your approach.")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            } else if item.status == .completed {
                Text("Great job completing this item! Consider adding a reflection on what you learned.")
                    .font(.callout)
                    .foregroundColor(.green)
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var contentSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Notes section
            ContentSection(
                title: "Notes",
                icon: "note.text",
                content: notes,
                placeholder: "Add your notes, key insights, or important details here...",
                isEditing: $isEditingNotes,
                onSave: { newNotes in
                    item.addNotes(newNotes)
                    try? modelContext.save()
                }
            )
            
            // Reflection section
            ContentSection(
                title: "Reflection",
                icon: "lightbulb",
                content: reflection,
                placeholder: "What did you learn? How does this connect to other concepts? Any questions that came up?",
                isEditing: $isEditingReflection,
                onSave: { newReflection in
                    item.addReflection(newReflection)
                    try? modelContext.save()
                }
            )
        }
    }
    
    private var capturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Captures")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(item.captures) { capture in
                    EnhancedCaptureRowView(capture: capture)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Add Screenshot",
                    icon: "camera.fill",
                    color: .blue
                ) {
                    showingAttachmentPicker = true
                }
                
                ActionButton(
                    title: "Link Capture",
                    icon: "link.badge.plus",
                    color: .purple
                ) {
                    // TODO: Show capture picker
                }
                
                ActionButton(
                    title: "AI Summary",
                    icon: "sparkles",
                    color: .orange
                ) {
                    // TODO: Generate AI summary
                }
                .disabled(true) // TODO: Enable when AI integration is ready
                
                Spacer()
            }
        }
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(statusColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                if item.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(statusColor)
                } else if item.status == .inProgress {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 20, height: 20)
                }
            }
            
            Text(item.status.displayName)
                .font(.caption2.weight(.medium))
                .foregroundColor(statusColor)
        }
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
    
    private func formatPageReference() -> String {
        guard let pageRef = item.pageReference else { return "" }
        
        // If packet has sections, try to show "p. X of Y" format
        if !packet.sections.isEmpty {
            let pageNumbers = packet.sections.compactMap { section in
                section.pageReference?.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap(Int.init)
                    .max()
            }
            
            if let maxPage = pageNumbers.max() {
                return "Page \(pageRef) of \(maxPage)"
            }
        }
        
        return "Page \(pageRef)"
    }
    
    private func updateStatus(_ newStatus: ItemStatus) {
        item.updateStatus(newStatus)
        try? modelContext.save()
    }
}

struct ContentSection: View {
    let title: String
    let icon: String
    let content: String
    let placeholder: String
    @Binding var isEditing: Bool
    let onSave: (String) -> Void
    
    @State private var editingText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                Spacer()
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        onSave(editingText)
                        isEditing = false
                    } else {
                        editingText = content
                        isEditing = true
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if isEditing {
                TextEditor(text: $editingText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
            } else {
                if !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                } else {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct EnhancedCaptureRowView: View {
    let capture: Capture
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: capture.type.systemImageName)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(capture.title)
                    .font(.subheadline.weight(.medium))
                
                HStack {
                    Text(capture.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !capture.displayDuration.isEmpty {
                        Text("• \(capture.displayDuration)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Button("View") {
                // TODO: Show capture detail
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    let item = ChecklistItem(title: "Review Chapter 3: Advanced SwiftUI Architecture Patterns", pageReference: "45", order: 0)
    item.addNotes("Key concepts include state management with @StateObject, @ObservedObject, and @EnvironmentObject. Also covers custom view modifiers and preference keys.")
    item.addReflection("This chapter really helped clarify the differences between different property wrappers. The examples with preference keys were particularly illuminating.")
    item.updateStatus(.inProgress)
    
    let packet = Packet(title: "SwiftUI Mastery Guide")
    
    return EnhancedItemDetailView(item: item, packet: packet)
        .modelContainer(for: [ChecklistItem.self, Packet.self, Capture.self], inMemory: true)
}