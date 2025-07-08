//
//  PacketOverviewCard.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct PacketOverviewCard: View {
    let packet: Packet
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and source
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(packet.title)
                            .font(.title2.weight(.semibold))
                            .lineLimit(2)
                        
                        if let sourceURL = packet.sourceURL {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.caption2)
                                Text(sourceURL.lastPathComponent)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    statusIndicator
                }
                
                // Timestamps
                HStack {
                    Text("Created \(packet.createdAt, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if packet.modifiedAt != packet.createdAt {
                        Text("• Updated \(packet.modifiedAt, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Progress section
            progressSection
            
            // Stats grid
            statsGrid
            
            // Quick actions
            if !packet.checklistItems.isEmpty {
                quickActions
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(progressColor)
                .frame(width: 8, height: 8)
            
            Text(progressStatus)
                .font(.caption.weight(.medium))
                .foregroundColor(progressColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(progressColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(completedItems)/\(totalItems) items")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.gradient)
                        .frame(width: geometry.size.width * packet.progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: packet.progress)
                }
            }
            .frame(height: 8)
            
            // Progress percentage
            HStack {
                Text("\(Int(packet.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if packet.progress > 0 && packet.progress < 1 {
                    Text("\(remainingItems) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            // Sections count
            OverviewStatCard(
                title: "Sections",
                value: "\(packet.sections.count)",
                icon: "doc.text",
                color: .blue
            )
            
            // Captures count
            OverviewStatCard(
                title: "Captures",
                value: "\(totalCaptures)",
                icon: "link",
                color: .purple
            )
            
            // Time estimate
            OverviewStatCard(
                title: "Est. Time",
                value: estimatedTime,
                icon: "clock",
                color: .orange
            )
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Next Item",
                    icon: "arrow.right.circle.fill",
                    color: .blue
                ) {
                    // TODO: Navigate to next pending item
                }
                .disabled(nextPendingItem == nil)
                
                ActionButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: .green
                ) {
                    // TODO: Quick add note
                }
                
                ActionButton(
                    title: "Review",
                    icon: "checkmark.circle",
                    color: .orange
                ) {
                    // TODO: Review completed items
                }
                .disabled(completedItems == 0)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalItems: Int {
        packet.checklistItems.count
    }
    
    private var completedItems: Int {
        packet.checklistItems.filter { $0.status == .completed }.count
    }
    
    private var remainingItems: Int {
        totalItems - completedItems
    }
    
    private var totalCaptures: Int {
        packet.captures.count
    }
    
    private var progressColor: Color {
        switch packet.progress {
        case 0: return .secondary
        case 0..<0.5: return .orange
        case 0.5..<1.0: return .blue
        case 1.0: return .green
        default: return .secondary
        }
    }
    
    private var progressStatus: String {
        switch packet.progress {
        case 0: return "Not Started"
        case 0..<0.5: return "Beginning"
        case 0.5..<1.0: return "In Progress"
        case 1.0: return "Completed"
        default: return "Unknown"
        }
    }
    
    private var estimatedTime: String {
        // Rough estimate: 10 minutes per item
        let minutes = totalItems * 10
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
    
    private var nextPendingItem: ChecklistItem? {
        packet.checklistItems
            .sorted { $0.order < $1.order }
            .first { $0.status == .pending }
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isEnabled ? color : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? color.opacity(0.15) : Color(NSColor.separatorColor))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let packet = Packet(title: "Advanced SwiftUI Patterns & Architecture", sourceURL: URL(string: "file:///Users/test/Documents/swiftui-guide.pdf"))
    
    // Add some mock data
    let item1 = ChecklistItem(title: "Chapter 1: State Management", pageReference: "12", order: 0)
    item1.updateStatus(.completed)
    item1.packet = packet
    
    let item2 = ChecklistItem(title: "Chapter 2: Custom View Modifiers", pageReference: "34", order: 1)
    item2.updateStatus(.inProgress)
    item2.packet = packet
    
    let item3 = ChecklistItem(title: "Chapter 3: Advanced Animations", pageReference: "56", order: 2)
    item3.packet = packet
    
    return PacketOverviewCard(packet: packet)
        .padding()
        .modelContainer(for: [Packet.self, ChecklistItem.self], inMemory: true)
}