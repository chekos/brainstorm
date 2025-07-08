//
//  PacketDetailView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct PacketDetailView: View {
    let packet: Packet
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: ChecklistItem?
    @State private var showingAddItemSheet = false
    @State private var showingSectionsView = false
    
    var body: some View {
        HSplitView {
            // Checklist view
            checklistView
                .frame(minWidth: 300)
            
            // Detail view
            detailView
                .frame(minWidth: 400)
        }
        .navigationTitle(packet.title)
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingAddItemSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                
                if !packet.sections.isEmpty {
                    Button(action: { showingSectionsView = true }) {
                        Label("View Sections (\(packet.sections.count))", systemImage: "doc.text")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddItemSheet(packet: packet)
        }
        .sheet(isPresented: $showingSectionsView) {
            PacketSectionsView(packet: packet)
        }
    }
    
    private var checklistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Checklist")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(completedItemsCount)/\(packet.checklistItems.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: packet.progress)
                    .tint(.accentColor)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Items list
            if packet.checklistItems.isEmpty {
                EmptyStateView(
                    title: "No Items Yet",
                    description: "Add items to this packet to start tracking your progress.",
                    systemImage: "list.bullet"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedItems) { item in
                            ChecklistItemRowView(
                                item: item,
                                isSelected: selectedItem?.id == item.id
                            ) {
                                selectedItem = item
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var detailView: some View {
        VStack {
            if let item = selectedItem {
                ChecklistItemDetailView(item: item)
            } else {
                EmptyStateView(
                    title: "Select an Item",
                    description: "Choose an item from the checklist to view its details and progress.",
                    systemImage: "checkmark.circle"
                )
            }
        }
    }
    
    private var sortedItems: [ChecklistItem] {
        packet.checklistItems.sorted { $0.order < $1.order }
    }
    
    private var completedItemsCount: Int {
        packet.checklistItems.filter { $0.status == .completed }.count
    }
}

struct ChecklistItemRowView: View {
    let item: ChecklistItem
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Status button
                Button(action: toggleStatus) {
                    Image(systemName: item.status.systemImageName)
                        .foregroundColor(statusColor)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(2)
                    
                    HStack {
                        if !item.displayProgress.isEmpty {
                            Text(item.displayProgress)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        if !item.captures.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("\(item.captures.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
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

struct ChecklistItemDetailView: View {
    let item: ChecklistItem
    @Environment(\.modelContext) private var modelContext
    @State private var notes: String = ""
    @State private var reflection: String = ""
    @State private var isEditingNotes = false
    @State private var isEditingReflection = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.status.systemImageName)
                            .foregroundColor(statusColor)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            if !item.displayProgress.isEmpty {
                                Text(item.displayProgress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach(ItemStatus.allCases, id: \.self) { status in
                                Button(status.displayName) {
                                    item.updateStatus(status)
                                    try? modelContext.save()
                                }
                            }
                        } label: {
                            Text(item.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor.opacity(0.2))
                                .foregroundColor(statusColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let completedAt = item.completedAt {
                        Text("Completed \(completedAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Notes section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(isEditingNotes ? "Save" : "Edit") {
                            if isEditingNotes {
                                item.addNotes(notes)
                                try? modelContext.save()
                            } else {
                                notes = item.notes ?? ""
                            }
                            isEditingNotes.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if isEditingNotes {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    } else {
                        if let itemNotes = item.notes, !itemNotes.isEmpty {
                            Text(itemNotes)
                                .font(.body)
                                .textSelection(.enabled)
                        } else {
                            Text("No notes yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                // Reflection section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reflection")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(isEditingReflection ? "Save" : "Edit") {
                            if isEditingReflection {
                                item.addReflection(reflection)
                                try? modelContext.save()
                            } else {
                                reflection = item.reflection ?? ""
                            }
                            isEditingReflection.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if isEditingReflection {
                        TextEditor(text: $reflection)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    } else {
                        if let itemReflection = item.reflection, !itemReflection.isEmpty {
                            Text(itemReflection)
                                .font(.body)
                                .textSelection(.enabled)
                        } else {
                            Text("No reflection yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                // Linked captures
                if !item.captures.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked Captures")
                            .font(.headline)
                        
                        ForEach(item.captures) { capture in
                            HStack {
                                Image(systemName: capture.type.systemImageName)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(capture.title)
                                        .font(.subheadline)
                                    
                                    Text(capture.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !capture.displayDuration.isEmpty {
                                    Text(capture.displayDuration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            notes = item.notes ?? ""
            reflection = item.reflection ?? ""
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
}

struct AddItemSheet: View {
    let packet: Packet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var pageReference = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $title)
                    TextField("Page Reference (optional)", text: $pageReference)
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = ChecklistItem(
            title: title,
            pageReference: pageReference.isEmpty ? nil : pageReference,
            order: packet.checklistItems.count
        )
        newItem.packet = packet
        modelContext.insert(newItem)
        try? modelContext.save()
    }
}

#Preview {
    let packet = Packet(title: "Sample Packet")
    return PacketDetailView(packet: packet)
        .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}