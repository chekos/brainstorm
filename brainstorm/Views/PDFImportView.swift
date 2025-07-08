//
//  PDFImportView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct PDFImportView: View {
    @Environment(\.serviceContainer) private var serviceContainer
    @State private var importState: ImportState = .ready
    @State private var importedPacket: Packet?
    @State private var errorMessage: String?
    
    let onPacketImported: (Packet) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            switch importState {
            case .ready:
                PDFDropZone { url in
                    Task {
                        await importPDF(from: url)
                    }
                }
                
            case .importing(let filename):
                importingView(filename: filename)
                
            case .completed(let packet):
                completedView(packet: packet)
                
            case .failed(let error):
                failedView(error: error)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func importingView(filename: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Importing \(filename)")
                .font(.headline)
            
            Text("Parsing sections and generating checklist...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func completedView(packet: Packet) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Import Successful!")
                .font(.title)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Packet:")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(packet.title)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Sections:")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(packet.sections.count)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Checklist Items:")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(packet.checklistItems.count)")
                        .fontWeight(.medium)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .frame(maxWidth: 400)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Import Another") {
                    resetImport()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Open Packet") {
                    onPacketImported(packet)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func failedView(error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Import Failed")
                .font(.title)
                .fontWeight(.medium)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .frame(maxWidth: 400)
            
            Spacer()
            
            Button("Try Again") {
                resetImport()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func importPDF(from url: URL) async {
        guard let serviceContainer = serviceContainer else { return }
        
        let filename = url.lastPathComponent
        importState = .importing(filename)
        
        let result = await serviceContainer.pdfService.importPDF(from: url)
        
        await MainActor.run {
            switch result {
            case .success(let packet):
                importState = .completed(packet)
                importedPacket = packet
            case .failure(let error):
                importState = .failed(error.localizedDescription)
            }
        }
    }
    
    private func resetImport() {
        importState = .ready
        importedPacket = nil
        errorMessage = nil
    }
}

enum ImportState {
    case ready
    case importing(String)
    case completed(Packet)
    case failed(String)
}

#Preview {
    PDFImportView { packet in
        print("Imported packet: \(packet.title)")
    }
    .frame(width: 600, height: 500)
}