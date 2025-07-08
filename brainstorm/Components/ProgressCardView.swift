//
//  ProgressCardView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct ProgressCardView: View {
    let title: String
    let subtitle: String?
    let progress: Double
    let status: CardStatus
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, progress: Double, status: CardStatus = .active, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.status = status
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    StatusIndicator(status: status)
                }
                
                // Progress section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress)
                        .tint(status.color)
                        .scaleEffect(y: 0.8)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

enum CardStatus {
    case active
    case completed
    case blocked
    case paused
    
    var color: Color {
        switch self {
        case .active: return .accentColor
        case .completed: return .green
        case .blocked: return .red
        case .paused: return .orange
        }
    }
    
    var systemImage: String {
        switch self {
        case .active: return "circle.dotted"
        case .completed: return "checkmark.circle.fill"
        case .blocked: return "exclamationmark.triangle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
}

struct StatusIndicator: View {
    let status: CardStatus
    
    var body: some View {
        Image(systemName: status.systemImage)
            .foregroundColor(status.color)
            .font(.title2)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressCardView(
            title: "Research Paper Analysis",
            subtitle: "Updated 2 hours ago",
            progress: 0.65,
            status: .active
        ) {
            print("Card tapped")
        }
        
        ProgressCardView(
            title: "Literature Review",
            subtitle: "Completed yesterday",
            progress: 1.0,
            status: .completed
        ) {
            print("Card tapped")
        }
        
        ProgressCardView(
            title: "Data Collection",
            subtitle: "Blocked - missing access",
            progress: 0.25,
            status: .blocked
        ) {
            print("Card tapped")
        }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
}