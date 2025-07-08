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
    private let aiService: AIServiceRouter
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.aiService = AIServiceRouter()
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
            // Extract raw text from PDF
            let rawText = extractRawText(from: pdfDocument)
            
            // Use AI to analyze document
            let analysis = try await aiService.analyzeDocument(rawText, title: title)
            
            // Create sections from AI analysis
            let sections = createSectionsFromAnalysis(analysis)
            packet.sections = sections
            
            // Generate intelligent checklist items
            let checklistItems = createChecklistItemsFromAnalysis(analysis)
            packet.checklistItems = checklistItems
            
            // Save to context
            modelContext.insert(packet)
            try modelContext.save()
            
            return .success(packet)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
    
    // MARK: - PDF Text Extraction
    
    private func extractRawText(from document: PDFDocument) -> String {
        var fullText = ""
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            guard let pageContent = page.string else { continue }
            
            fullText += "\n=== Page \(pageIndex + 1) ===\n"
            fullText += pageContent
            fullText += "\n"
        }
        
        return fullText
    }
    
    // MARK: - AI Analysis Integration
    
    private func createSectionsFromAnalysis(_ analysis: DocumentAnalysis) -> [PacketSection] {
        var sections: [PacketSection] = []
        var order = 0
        
        // Create overview section
        let overviewSection = PacketSection(
            title: "Document Overview",
            content: analysis.summary,
            pageReference: "p. 1",
            sectionType: .content,
            order: order
        )
        sections.append(overviewSection)
        order += 1
        
        // Create sections for main topics
        for topic in analysis.mainTopics {
            let topicSection = PacketSection(
                title: topic.name,
                content: topic.description,
                pageReference: topic.pageReference,
                sectionType: .heading,
                order: order
            )
            sections.append(topicSection)
            order += 1
        }
        
        // Create sections for key concepts
        if !analysis.concepts.isEmpty {
            let conceptsContent = analysis.concepts.map { concept in
                "**\(concept.name)**: \(concept.definition)\n\n*Importance*: \(concept.importance)"
            }.joined(separator: "\n\n")
            
            let conceptsSection = PacketSection(
                title: "Key Concepts",
                content: conceptsContent,
                pageReference: nil,
                sectionType: .content,
                order: order
            )
            sections.append(conceptsSection)
            order += 1
        }
        
        // Create timeline section if we have dates
        if !analysis.keyDates.isEmpty {
            let timelineContent = analysis.keyDates.map { date in
                "**\(date.date)**: \(date.event)\n\(date.significance)"
            }.joined(separator: "\n\n")
            
            let timelineSection = PacketSection(
                title: "Timeline",
                content: timelineContent,
                pageReference: nil,
                sectionType: .content,
                order: order
            )
            sections.append(timelineSection)
            order += 1
        }
        
        // Create figures section if we have important people
        if !analysis.importantFigures.isEmpty {
            let figuresContent = analysis.importantFigures.map { figure in
                "**\(figure.name)** (\(figure.timeframe ?? "Unknown period"))\n*Role*: \(figure.role)\n*Significance*: \(figure.significance)"
            }.joined(separator: "\n\n")
            
            let figuresSection = PacketSection(
                title: "Important Figures",
                content: figuresContent,
                pageReference: nil,
                sectionType: .content,
                order: order
            )
            sections.append(figuresSection)
            order += 1
        }
        
        return sections
    }
    
    // MARK: - Legacy Heading Detection (Backup)
    // Kept for fallback when AI service is unavailable
    
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
    
    // MARK: - AI-Powered Checklist Generation
    
    private func createChecklistItemsFromAnalysis(_ analysis: DocumentAnalysis) -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        var order = 0
        
        // Create checklist items from AI-generated study tasks
        for task in analysis.studyTasks {
            let item = ChecklistItem(
                title: task.title,
                pageReference: task.pageReference,
                order: order
            )
            // Add task details to notes if available
            if !task.description.isEmpty {
                item.notes = task.description
            }
            items.append(item)
            order += 1
        }
        
        // Ensure we have at least some items
        if items.isEmpty {
            // Fallback to topic-based items
            for topic in analysis.mainTopics {
                let item = ChecklistItem(
                    title: "Study \(topic.name)",
                    pageReference: topic.pageReference,
                    order: order
                )
                item.notes = topic.description
                items.append(item)
                order += 1
            }
        }
        
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