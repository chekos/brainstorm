//
//  TodaysDeskView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import SwiftData

struct TodaysDeskView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recentCaptures: [Capture]
    @State private var selectedCapture: Capture?
    
    // Filter captures from last 24 hours
    private var todaysCaptures: [Capture] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return recentCaptures.filter { $0.timestamp >= yesterday }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with date and activity sparkline
                headerView
                
                HSplitView {
                    // Captures list
                    capturesList
                    
                    // Detail view
                    detailView
                }
            }
            .navigationTitle("Today's Desk")
            .toolbar {
                ToolbarItem {
                    Button(action: {}) {
                        Label("New Capture", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Thursday, July 8")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Activity sparkline (placeholder)
                HStack(spacing: 2) {
                    Text("Captures")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SparklineView(values: generateSparklineData())
                        .frame(width: 60, height: 20)
                }
            }
            
            Text("\(todaysCaptures.count) captures in the last 24 hours")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var capturesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if todaysCaptures.isEmpty {
                EmptyStateView(
                    title: "No Captures Today",
                    description: "Start capturing ideas with voice notes, screen clips, or brainstorm sessions.",
                    systemImage: "waveform"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(todaysCaptures) { capture in
                            CaptureRowView(
                                capture: capture,
                                isSelected: selectedCapture?.id == capture.id
                            ) {
                                selectedCapture = capture
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 300)
    }
    
    private var detailView: some View {
        VStack {
            if let capture = selectedCapture {
                CaptureDetailView(capture: capture)
            } else {
                EmptyStateView(
                    title: "Select a Capture",
                    description: "Choose a capture from the list to view its details and linked items.",
                    systemImage: "doc.text.magnifyingglass"
                )
            }
        }
        .frame(minWidth: 400)
    }
    
    private func generateSparklineData() -> [Double] {
        // Generate sample data for sparkline
        let hours = Array(0..<24)
        return hours.map { hour in
            let capturesInHour = todaysCaptures.filter { capture in
                Calendar.current.component(.hour, from: capture.timestamp) == hour
            }.count
            return Double(capturesInHour)
        }
    }
}

struct CaptureRowView: View {
    let capture: Capture
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Type indicator
                Image(systemName: capture.type.systemImageName)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(timeFormatter.string(from: capture.timestamp))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        
                        Spacer()
                        
                        if capture.type == .voice || capture.type == .brainstorm {
                            Text(capture.displayDuration)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                    }
                    
                    Text(capture.title)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    
                    if !capture.content.isEmpty {
                        Text(capture.content)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .lineLimit(2)
                    }
                    
                    if !capture.linkedItems.isEmpty {
                        HStack {
                            Image(systemName: "link")
                                .font(.caption2)
                            Text("\(capture.linkedItems.count) linked")
                                .font(.caption2)
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(capture.linkedItems.isEmpty ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
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
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}

struct CaptureDetailView: View {
    let capture: Capture
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: capture.type.systemImageName)
                            .foregroundColor(.accentColor)
                        
                        Text(capture.type.displayName)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(capture.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(capture.title)
                        .font(.title2)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    if !capture.content.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Content")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(capture.content)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                    
                    if let transcript = capture.transcript {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transcript")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(transcript)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                    
                    if let summary = capture.summary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Summary")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(summary)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                }
                
                if !capture.linkedItems.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked Items")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(capture.linkedItems) { item in
                            HStack {
                                Image(systemName: item.status.systemImageName)
                                    .foregroundColor(.accentColor)
                                
                                Text(item.title)
                                    .font(.body)
                                
                                Spacer()
                                
                                if !item.displayProgress.isEmpty {
                                    Text(item.displayProgress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack {
                    Button("Create Task") {
                        // TODO: Implement task creation
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Link") {
                        // TODO: Implement linking
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct SparklineView: View {
    let values: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = values.max() ?? 1
            let width = geometry.size.width
            let height = geometry.size.height
            let barWidth = width / CGFloat(values.count)
            
            HStack(spacing: 0) {
                ForEach(0..<values.count, id: \.self) { index in
                    let value = values[index]
                    let barHeight = maxValue > 0 ? (value / maxValue) * height : 0
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: barWidth, height: barHeight)
                        .alignmentGuide(.bottom) { _ in 0 }
                }
            }
        }
    }
}

#Preview {
    TodaysDeskView()
        .modelContainer(for: [Packet.self, PacketSection.self, ChecklistItem.self, Capture.self], inMemory: true)
}