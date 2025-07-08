//
//  PDFDropZone.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFDropZone: View {
    let onDrop: (URL) -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(isHovering ? .accentColor : .secondary)
            
            VStack(spacing: 8) {
                Text("Drop PDF Here")
                    .font(.headline)
                    .foregroundColor(isHovering ? .accentColor : .primary)
                
                Text("Drag and drop a PDF file to create a new packet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Or Browse Files") {
                browseForFile()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isHovering ? Color.accentColor : Color.secondary.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        )
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
            handleDrop(providers)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url, url.pathExtension.lowercased() == "pdf" {
                    onDrop(url)
                }
            }
        }
        
        return true
    }
    
    private func browseForFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            onDrop(url)
        }
    }
}

#Preview {
    PDFDropZone { url in
        print("Dropped PDF: \(url)")
    }
    .padding()
    .frame(width: 400, height: 300)
}