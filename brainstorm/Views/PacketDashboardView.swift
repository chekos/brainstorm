//
//  PacketDashboardView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct PacketDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var packets: [Packet]
    @State private var selectedPacket: Packet?
    @State private var showingArchivedPackets = false
    
    private var activePackets: [Packet] {
        packets.filter { !$0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    private var archivedPackets: [Packet] {
        packets.filter { $0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                statsHeader
                
                // Packets grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(showingArchivedPackets ? archivedPackets : activePackets) { packet in
                            PacketCardView(packet: packet) {
                                selectedPacket = packet
                            }
                        }
                    }
                    .padding()
                }
                
                if activePackets.isEmpty && !showingArchivedPackets {
                    EmptyStateView(
                        title: "No Packets Yet",
                        description: "Import your first study packet to get started with your research workflow.",
                        systemImage: "doc.badge.plus"
                    )
                }
            }
            .navigationTitle("Packet Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewPacket) {
                        Label("New Packet", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button(showingArchivedPackets ? "Show Active" : "Show Archived") {
                        showingArchivedPackets.toggle()
                    }
                }
            }
        }
        .sheet(item: $selectedPacket) { packet in
            PacketDetailSheet(packet: packet)
        }
    }
    
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: "Active Packets",
                    value: "\(activePackets.count)",
                    icon: "doc.text",
                    color: .blue
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(activePackets.filter { $0.isCompleted }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatCard(
                    title: "In Progress",
                    value: "\(activePackets.filter { !$0.isCompleted && $0.progress > 0 }.count)",
                    icon: "circle.dotted",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Items",
                    value: "\(activePackets.reduce(0) { $0 + $1.checklistItems.count })",
                    icon: "list.bullet",
                    color: .purple
                )
            }
            
            // Overall progress bar
            if !activePackets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(overallProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: overallProgress)
                        .tint(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var overallProgress: Double {
        guard !activePackets.isEmpty else { return 0 }
        let totalItems = activePackets.reduce(0) { $0 + $1.checklistItems.count }
        guard totalItems > 0 else { return 0 }
        let completedItems = activePackets.reduce(0) { total, packet in
            total + packet.checklistItems.filter { $0.status == .completed }.count
        }
        return Double(completedItems) / Double(totalItems)
    }
    
    private func createNewPacket() {
        let newPacket = Packet(title: "New Packet")
        modelContext.insert(newPacket)
        
        // Add sample checklist item
        let sampleItem = ChecklistItem(title: "Get started with this packet", order: 0)
        sampleItem.packet = newPacket
        modelContext.insert(sampleItem)
        
        selectedPacket = newPacket
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct PacketCardView: View {
    let packet: Packet
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(packet.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(packet.modifiedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if packet.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else if packet.progress > 0 {
                        Image(systemName: "circle.dotted")
                            .foregroundColor(.orange)
                            .font(.title2)
                    }
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(packet.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: packet.progress)
                        .tint(.accentColor)
                }
                
                // Stats
                HStack {
                    Label("\(packet.checklistItems.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(packet.captures.count)", systemImage: "waveform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if packet.sections.count > 0 {
                        Label("\(packet.sections.count)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}

struct PacketDetailSheet: View {
    let packet: Packet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PacketDetailView(packet: packet)
                .navigationTitle(packet.title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    PacketDashboardView()
        .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}