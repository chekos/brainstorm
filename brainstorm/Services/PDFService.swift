//
//  PDFService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation
import PDFKit
import SwiftData

@MainActor
class PDFService: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - PDF Import
    
    func importPDF(from url: URL) async -> Result<Packet, PDFImportError> {
        guard url.pathExtension.lowercased() == "pdf" else {
            return .failure(.invalidFileType)
        }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            return .failure(.failedToLoadPDF)
        }
        
        // Create packet with basic info
        let filename = url.lastPathComponent
        let title = url.deletingPathExtension().lastPathComponent
        let packet = Packet(title: title, sourceURL: url, originalFilename: filename)
        
        do {
            // Parse PDF content
            let sections = try await parsePDFDocument(pdfDocument)
            packet.sections = sections
            
            // Generate checklist items
            let checklistItems = generateChecklistItems(from: sections, packet: packet)
            packet.checklistItems = checklistItems
            
            // Save to context
            modelContext.insert(packet)
            try modelContext.save()
            
            return .success(packet)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
    
    // MARK: - PDF Parsing
    
    private func parsePDFDocument(_ document: PDFDocument) async throws -> [PacketSection] {
        var sections: [PacketSection] = []
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            guard let pageContent = page.string else { continue }
            
            let pageNumber = pageIndex + 1
            let pageSections = parsePageContent(pageContent, pageNumber: pageNumber)
            sections.append(contentsOf: pageSections)
        }
        
        return sections
    }
    
    private func parsePageContent(_ content: String, pageNumber: Int) -> [PacketSection] {
        var sections: [PacketSection] = []
        let lines = content.components(separatedBy: .newlines)
        var currentContent: [String] = []
        var currentTitle: String?
        var sectionOrder = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            // Detect headings using various heuristics
            if isHeading(trimmedLine) {
                // Save previous section if exists
                if let title = currentTitle, !currentContent.isEmpty {
                    let section = PacketSection(
                        title: title,
                        content: currentContent.joined(separator: "\n"),
                        pageReference: "p. \(pageNumber)",
                        sectionType: .heading,
                        order: sectionOrder
                    )
                    sections.append(section)
                    sectionOrder += 1
                }
                
                // Start new section
                currentTitle = trimmedLine
                currentContent = []
            } else {
                // Add to current content
                currentContent.append(trimmedLine)
            }
        }
        
        // Save final section
        if let title = currentTitle, !currentContent.isEmpty {
            let section = PacketSection(
                title: title,
                content: currentContent.joined(separator: "\n"),
                pageReference: "p. \(pageNumber)",
                sectionType: .content,
                order: sectionOrder
            )
            sections.append(section)
        } else if !currentContent.isEmpty {
            // Content without heading
            let section = PacketSection(
                title: "Page \(pageNumber) Content",
                content: currentContent.joined(separator: "\n"),
                pageReference: "p. \(pageNumber)",
                sectionType: .content,
                order: sectionOrder
            )
            sections.append(section)
        }
        
        return sections
    }
    
    // MARK: - Heading Detection
    
    private func isHeading(_ text: String) -> Bool {
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty or very short lines are not headings
        guard line.count > 2 && line.count < 200 else { return false }
        
        // Common heading patterns
        let headingPatterns = [
            // Numbered sections: "1. Introduction", "2.1 Overview"
            "^\\d+(\\.\\d+)*\\.?\\s+[A-Z]",
            // All caps headings: "METHODOLOGY"
            "^[A-Z][A-Z\\s]{3,}$",
            // Title case with minimal punctuation
            "^[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)*:?$",
            // Roman numerals: "I. Introduction", "IV. Results"
            "^[IVX]+\\.\\s+[A-Z]",
            // Lettered sections: "A. Overview", "B. Methods"
            "^[A-Z]\\.\\s+[A-Z]"
        ]
        
        for pattern in headingPatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        // Length-based heuristic for short lines that might be headings
        if line.count < 80 && !line.contains(".") && !line.contains(",") {
            // Check if it starts with a capital and has title-like characteristics
            let words = line.components(separatedBy: .whitespaces)
            if words.count >= 1 && words.count <= 8 {
                let capitalizedWords = words.filter { word in
                    !word.isEmpty && word.first?.isUppercase == true
                }
                if capitalizedWords.count >= words.count / 2 {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Checklist Generation
    
    private func generateChecklistItems(from sections: [PacketSection], packet: Packet) -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        var order = 0
        
        // Group sections by type and importance
        let headings = sections.filter { $0.sectionType == .heading }
        
        for heading in headings {
            let item = ChecklistItem(
                title: heading.title,
                pageReference: heading.pageReference,
                order: order
            )
            item.packet = packet
            items.append(item)
            order += 1
        }
        
        // If no clear headings, create items based on content sections
        if items.isEmpty {
            let contentSections = sections.filter { $0.sectionType == .content }
            for section in contentSections.prefix(10) { // Limit to prevent overwhelming lists
                let item = ChecklistItem(
                    title: section.title,
                    pageReference: section.pageReference,
                    order: order
                )
                item.packet = packet
                items.append(item)
                order += 1
            }
        }
        
        // Add a completion item
        let completionItem = ChecklistItem(
            title: "Review and summarize key findings",
            pageReference: nil,
            order: order
        )
        completionItem.packet = packet
        items.append(completionItem)
        
        return items
    }
}

// MARK: - Error Types

enum PDFImportError: LocalizedError {
    case invalidFileType
    case failedToLoadPDF
    case parsingFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "The selected file is not a PDF"
        case .failedToLoadPDF:
            return "Failed to load the PDF document"
        case .parsingFailed(let details):
            return "Failed to parse PDF content: \(details)"
        case .saveFailed(let details):
            return "Failed to save packet: \(details)"
        }
    }
}