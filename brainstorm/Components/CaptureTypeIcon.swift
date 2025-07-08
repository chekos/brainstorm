//
//  CaptureTypeIcon.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct CaptureTypeIcon: View {
    let type: CaptureType
    let size: IconSize
    let showBackground: Bool
    
    init(_ type: CaptureType, size: IconSize = .medium, showBackground: Bool = true) {
        self.type = type
        self.size = size
        self.showBackground = showBackground
    }
    
    var body: some View {
        Image(systemName: type.systemImageName)
            .font(size.font)
            .foregroundColor(showBackground ? .white : type.color)
            .frame(width: size.dimension, height: size.dimension)
            .background(
                showBackground ? 
                Circle().fill(type.color) : 
                Circle().fill(Color.clear)
            )
    }
}

enum IconSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .title3
        case .large: return .title
        }
    }
    
    var dimension: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        }
    }
}

extension CaptureType {
    var color: Color {
        switch self {
        case .voice: return .blue
        case .screenClip: return .green
        case .brainstorm: return .purple
        case .text: return .gray
        case .image: return .orange
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            CaptureTypeIcon(.voice, size: .small)
            CaptureTypeIcon(.screenClip, size: .small)
            CaptureTypeIcon(.brainstorm, size: .small)
            CaptureTypeIcon(.text, size: .small)
            CaptureTypeIcon(.image, size: .small)
        }
        
        HStack(spacing: 16) {
            CaptureTypeIcon(.voice, size: .medium)
            CaptureTypeIcon(.screenClip, size: .medium)
            CaptureTypeIcon(.brainstorm, size: .medium)
            CaptureTypeIcon(.text, size: .medium)
            CaptureTypeIcon(.image, size: .medium)
        }
        
        HStack(spacing: 16) {
            CaptureTypeIcon(.voice, size: .large)
            CaptureTypeIcon(.screenClip, size: .large)
            CaptureTypeIcon(.brainstorm, size: .large)
            CaptureTypeIcon(.text, size: .large)
            CaptureTypeIcon(.image, size: .large)
        }
        
        Text("Without Background")
            .font(.headline)
            .padding(.top)
        
        HStack(spacing: 16) {
            CaptureTypeIcon(.voice, size: .medium, showBackground: false)
            CaptureTypeIcon(.screenClip, size: .medium, showBackground: false)
            CaptureTypeIcon(.brainstorm, size: .medium, showBackground: false)
            CaptureTypeIcon(.text, size: .medium, showBackground: false)
            CaptureTypeIcon(.image, size: .medium, showBackground: false)
        }
    }
    .padding()
}