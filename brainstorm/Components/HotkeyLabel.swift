//
//  HotkeyLabel.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct HotkeyLabel: View {
    let keys: [String]
    let description: String
    let style: HotkeyStyle
    
    init(_ keys: [String], description: String, style: HotkeyStyle = .compact) {
        self.keys = keys
        self.description = description
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: style.spacing) {
            HStack(spacing: 2) {
                ForEach(keys, id: \.self) { key in
                    KeyView(key: key, style: style)
                }
            }
            
            if style == .detailed {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct KeyView: View {
    let key: String
    let style: HotkeyStyle
    
    var body: some View {
        Text(key)
            .font(style.font)
            .foregroundColor(.primary)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(Color(NSColor.controlColor))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
    }
}

enum HotkeyStyle {
    case compact
    case detailed
    
    var font: Font {
        switch self {
        case .compact: return .caption2
        case .detailed: return .caption
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .detailed: return 8
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 4
        case .detailed: return 6
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 2
        case .detailed: return 3
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 3
        case .detailed: return 4
        }
    }
}

// Common hotkey combinations
extension HotkeyLabel {
    static let screenClip = HotkeyLabel(["⌘", "⇧", "C"], description: "Screen Clip")
    static let voiceNote = HotkeyLabel(["⌥", "Space"], description: "Voice Note")
    static let brainstorm = HotkeyLabel(["⌘", "⇧", "B"], description: "Brainstorm")
    static let todaysDesk = HotkeyLabel(["⌘", "1"], description: "Today's Desk")
    static let packetDashboard = HotkeyLabel(["⌘", "2"], description: "Packet Dashboard")
    static let localOnly = HotkeyLabel(["⌥", "P"], description: "Local Only Mode")
}

#Preview {
    VStack(spacing: 20) {
        Text("Compact Style")
            .font(.headline)
        
        VStack(alignment: .leading, spacing: 8) {
            HotkeyLabel.screenClip
            HotkeyLabel.voiceNote
            HotkeyLabel.brainstorm
            HotkeyLabel.todaysDesk
            HotkeyLabel.packetDashboard
            HotkeyLabel.localOnly
        }
        
        Text("Detailed Style")
            .font(.headline)
            .padding(.top)
        
        VStack(alignment: .leading, spacing: 8) {
            HotkeyLabel(["⌘", "⇧", "C"], description: "Screen Clip", style: .detailed)
            HotkeyLabel(["⌥", "Space"], description: "Voice Note", style: .detailed)
            HotkeyLabel(["⌘", "⇧", "B"], description: "Brainstorm", style: .detailed)
            HotkeyLabel(["⌘", "1"], description: "Today's Desk", style: .detailed)
            HotkeyLabel(["⌘", "2"], description: "Packet Dashboard", style: .detailed)
            HotkeyLabel(["⌥", "P"], description: "Local Only Mode", style: .detailed)
        }
    }
    .padding()
}