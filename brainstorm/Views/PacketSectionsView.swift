//
//  PacketSectionsView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct PacketSectionsView: View {
    let packet: Packet
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: PacketSection?
    
    private var sortedSections: [PacketSection] {
        packet.sections.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // Sections list
                sectionsList
                    .frame(minWidth: 300)
                
                // Section detail
                sectionDetail
                    .frame(minWidth: 400)
            }
            .navigationTitle("Packet Sections")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var sectionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Sections")
                    .font(.headline)
                
                Spacer()
                
                Text("\(sortedSections.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            if sortedSections.isEmpty {
                EmptyStateView(
                    title: "No Sections",
                    description: "This packet doesn't have any parsed sections yet.",
                    systemImage: "doc.text"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedSections) { section in
                            SectionRowView(
                                section: section,
                                isSelected: selectedSection?.id == section.id
                            ) {
                                selectedSection = section
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var sectionDetail: some View {
        VStack {
            if let section = selectedSection {
                SectionDetailView(section: section)
            } else {
                EmptyStateView(
                    title: "Select a Section",
                    description: "Choose a section from the list to view its content.",
                    systemImage: "doc.text.magnifyingglass"
                )
            }
        }
    }
}

struct SectionRowView: View {
    let section: PacketSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.sectionType.systemImage)
                    .foregroundColor(isSelected ? .white : section.sectionType.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(2)
                    
                    HStack {
                        if let pageRef = section.pageReference {
                            Text(pageRef)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        Text(section.sectionType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.2) : section.sectionType.color.opacity(0.2))
                            )
                            .foregroundColor(isSelected ? .white : section.sectionType.color)
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
}

struct SectionDetailView: View {
    let section: PacketSection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: section.sectionType.systemImage)
                            .foregroundColor(section.sectionType.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            HStack {
                                if let pageRef = section.pageReference {
                                    Text(pageRef)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(section.sectionType.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(section.sectionType.color.opacity(0.2))
                                    )
                                    .foregroundColor(section.sectionType.color)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Text("Created \(section.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                    
                    Text(section.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

extension SectionType {
    var color: Color {
        switch self {
        case .heading: return .blue
        case .content: return .primary
        case .figure: return .green
        case .code: return .purple
        case .quote: return .orange
        case .list: return .indigo
        case .task: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .heading: return "text.line.first.and.arrowtriangle.forward"
        case .content: return "text.alignleft"
        case .figure: return "photo"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .quote: return "quote.bubble"
        case .list: return "list.bullet"
        case .task: return "checkmark.square"
        }
    }
}

#Preview {
    let packet = Packet(title: "Sample Packet")
    return PacketSectionsView(packet: packet)
}