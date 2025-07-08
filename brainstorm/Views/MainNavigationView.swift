//
//  MainNavigationView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct MainNavigationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var packets: [Packet]
    @State private var selectedView: NavigationDestination = .todaysDesk
    @State private var selectedPacket: Packet?
    @State private var showingImportView = false
    @State private var showingCaptureHUD = false
    @State private var showingAISettings = false
    
    @Environment(\.serviceContainer) private var serviceContainer
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Main navigation buttons
                VStack(spacing: 8) {
                    NavigationButton(
                        destination: .todaysDesk,
                        title: "Today's Desk",
                        icon: "calendar",
                        isSelected: selectedView == .todaysDesk
                    ) {
                        selectedView = .todaysDesk
                        selectedPacket = nil
                    }
                    
                    NavigationButton(
                        destination: .packetDashboard,
                        title: "Packet Dashboard",
                        icon: "square.grid.2x2",
                        isSelected: selectedView == .packetDashboard
                    ) {
                        selectedView = .packetDashboard
                        selectedPacket = nil
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Packets list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Packets")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(packets.filter { !$0.isArchived }.sorted { $0.modifiedAt > $1.modifiedAt }) { packet in
                                PacketRowView(packet: packet, isSelected: selectedPacket?.id == packet.id) {
                                    selectedView = .packet
                                    selectedPacket = packet
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Quick actions
                VStack(spacing: 8) {
                    Divider()
                    
                    Button(action: createNewPacket) {
                        Label("New Packet", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showingImportView = true }) {
                        Label("Import PDF", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { showingCaptureHUD = true }) {
                        Label("Quick Capture", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showingAISettings = true }) {
                        Label("AI Settings", systemImage: "brain")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Workbench")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
#endif
        } detail: {
            Group {
                switch selectedView {
                case .todaysDesk:
                    TodaysDeskView()
                case .packetDashboard:
                    PacketDashboardView()
                case .packet:
                    if let packet = selectedPacket {
                        PacketDetailView(packet: packet)
                    } else {
                        EmptyStateView(
                            title: "No Packet Selected",
                            description: "Select a packet from the sidebar to view its contents.",
                            systemImage: "doc.text"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingImportView) {
            PDFImportView { packet in
                selectedView = .packet
                selectedPacket = packet
                showingImportView = false
            }
            .frame(minWidth: 500, minHeight: 400)
            .frame(idealWidth: 600, idealHeight: 500)
        }
        .sheet(isPresented: $showingCaptureHUD) {
            if let services = serviceContainer {
                CaptureHUD(
                    voiceService: services.voiceService,
                    screenClipService: services.screenClipService,
                    brainstormService: services.brainstormService,
                    hotkeyService: services.hotkeyService
                )
                .frame(minWidth: 400, minHeight: 600)
                .frame(idealWidth: 450, idealHeight: 650)
                .onDisappear {
                    // Clean up any service references when the sheet is dismissed
                    showingCaptureHUD = false
                }
            } else {
                Text("Services not available")
                    .padding()
                    .frame(minWidth: 300, minHeight: 200)
                    .onAppear {
                        showingCaptureHUD = false
                    }
            }
        }
        .sheet(isPresented: $showingAISettings) {
            AISettingsView()
                .frame(minWidth: 500, minHeight: 400)
                .frame(idealWidth: 600, idealHeight: 500)
        }
    }
    
    private func createNewPacket() {
        let newPacket = Packet(title: "New Packet")
        modelContext.insert(newPacket)
        
        // Add sample checklist item
        let sampleItem = ChecklistItem(title: "Get started with this packet", order: 0)
        sampleItem.packet = newPacket
        modelContext.insert(sampleItem)
        
        selectedView = .packet
        selectedPacket = newPacket
    }
}

enum NavigationDestination {
    case todaysDesk
    case packetDashboard
    case packet
}

struct NavigationButton: View {
    let destination: NavigationDestination
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PacketRowView: View {
    let packet: Packet
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(packet.title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text("\(packet.checklistItems.count) items")
                            .font(.subheadline)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        
                        Spacer()
                        
                        if packet.progress > 0 {
                            Text("\(Int(packet.progress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                if packet.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(isSelected ? .white : .green)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let title: String
    let description: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

#Preview {
    MainNavigationView()
        .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}