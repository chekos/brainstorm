//
//  AIAnalysisService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation

// MARK: - Data Models for AI Analysis

struct DocumentAnalysis: Codable {
    let title: String
    let summary: String
    let mainTopics: [Topic]
    let studyTasks: [StudyTask]
    let keyDates: [HistoricalDate]
    let importantFigures: [Person]
    let concepts: [Concept]
    
    init(title: String = "Untitled Document", summary: String = "", mainTopics: [Topic] = [], studyTasks: [StudyTask] = [], keyDates: [HistoricalDate] = [], importantFigures: [Person] = [], concepts: [Concept] = []) {
        self.title = title
        self.summary = summary
        self.mainTopics = mainTopics
        self.studyTasks = studyTasks
        self.keyDates = keyDates
        self.importantFigures = importantFigures
        self.concepts = concepts
    }
}

struct Topic: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let priority: Priority
    let pageReference: String?
    
    init(name: String, description: String, priority: Priority, pageReference: String?) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.priority = priority
        self.pageReference = pageReference
    }
    
    enum Priority: String, Codable, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
}

struct StudyTask: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let taskType: TaskType
    let estimatedMinutes: Int
    let priority: Priority
    let pageReference: String?
    let relatedTopics: [String]
    
    init(title: String, description: String, taskType: TaskType, estimatedMinutes: Int, priority: Priority, pageReference: String?, relatedTopics: [String]) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.taskType = taskType
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.pageReference = pageReference
        self.relatedTopics = relatedTopics
    }
    
    enum TaskType: String, Codable, CaseIterable {
        case memorize = "memorize"
        case understand = "understand"
        case analyze = "analyze"
        case compare = "compare"
        case synthesize = "synthesize"
        case review = "review"
    }
    
    enum Priority: String, Codable, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
}

struct HistoricalDate: Codable, Identifiable {
    let id: UUID
    let date: String
    let event: String
    let significance: String
    let pageReference: String?
    
    init(date: String, event: String, significance: String, pageReference: String?) {
        self.id = UUID()
        self.date = date
        self.event = event
        self.significance = significance
        self.pageReference = pageReference
    }
}

struct Person: Codable, Identifiable {
    let id: UUID
    let name: String
    let role: String
    let significance: String
    let timeframe: String?
    let pageReference: String?
    
    init(name: String, role: String, significance: String, timeframe: String?, pageReference: String?) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.significance = significance
        self.timeframe = timeframe
        self.pageReference = pageReference
    }
}

struct Concept: Codable, Identifiable {
    let id: UUID
    let name: String
    let definition: String
    let importance: String
    let relatedConcepts: [String]
    let pageReference: String?
    
    init(name: String, definition: String, importance: String, relatedConcepts: [String], pageReference: String?) {
        self.id = UUID()
        self.name = name
        self.definition = definition
        self.importance = importance
        self.relatedConcepts = relatedConcepts
        self.pageReference = pageReference
    }
}

// MARK: - AI Service Protocol

protocol AIAnalysisService {
    func analyzeDocument(_ content: String, title: String?) async throws -> DocumentAnalysis
    func generateStudyTasks(_ analysis: DocumentAnalysis) async throws -> [StudyTask]
    func isAvailable() -> Bool
    var serviceName: String { get }
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case serviceUnavailable
    case invalidResponse
    case networkError(String)
    case apiError(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI service is not available"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}

// MARK: - AI Service Router

@MainActor
class AIServiceRouter: ObservableObject {
    private var services: [AIAnalysisService] = []
    
    init() {
        setupServices()
    }
    
    private func setupServices() {
        // Services in priority order: Real AI services first, then fallbacks
        var availableServices: [AIAnalysisService] = []
        
        // Try to get OpenAI API key from environment or configuration
        if let apiKey = getOpenAIApiKey(), !apiKey.isEmpty {
            availableServices.append(OpenAIService(apiKey: apiKey))
        }
        
        // Add mock as fallback
        availableServices.append(MockAIService())
        
        services = availableServices
    }
    
    private func getOpenAIApiKey() -> String? {
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Check for API key in user defaults (temporary storage)
        if let storedKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            return storedKey
        }
        
        return nil
    }
    
    func analyzeDocument(_ content: String, title: String? = nil) async throws -> DocumentAnalysis {
        for service in services {
            if service.isAvailable() {
                do {
                    let analysis = try await service.analyzeDocument(content, title: title)
                    print("✅ Document analysis completed using \(service.serviceName)")
                    return analysis
                } catch {
                    print("❌ Service \(service.serviceName) failed: \(error)")
                    continue
                }
            }
        }
        
        throw AIServiceError.serviceUnavailable
    }
    
    func generateStudyTasks(_ analysis: DocumentAnalysis) async throws -> [StudyTask] {
        for service in services {
            if service.isAvailable() {
                do {
                    let tasks = try await service.generateStudyTasks(analysis)
                    print("✅ Study tasks generated using \(service.serviceName)")
                    return tasks
                } catch {
                    print("❌ Service \(service.serviceName) failed for task generation: \(error)")
                    continue
                }
            }
        }
        
        throw AIServiceError.serviceUnavailable
    }
}

// MARK: - Mock AI Service for Development

private class MockAIService: AIAnalysisService {
    var serviceName: String = "Mock AI Service"
    
    func isAvailable() -> Bool {
        return true
    }
    
    func analyzeDocument(_ content: String, title: String?) async throws -> DocumentAnalysis {
        // Simulate AI processing delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Generate intelligent analysis based on content
        let analysisTitle = title ?? extractTitle(from: content)
        let summary = generateSummary(from: content)
        let topics = extractTopics(from: content)
        let dates = extractDates(from: content)
        let figures = extractFigures(from: content)
        let concepts = extractConcepts(from: content)
        let studyTasks = generateStudyTasks(from: content, topics: topics)
        
        return DocumentAnalysis(
            title: analysisTitle,
            summary: summary,
            mainTopics: topics,
            studyTasks: studyTasks,
            keyDates: dates,
            importantFigures: figures,
            concepts: concepts
        )
    }
    
    func generateStudyTasks(_ analysis: DocumentAnalysis) async throws -> [StudyTask] {
        return analysis.studyTasks
    }
    
    // MARK: - Mock Analysis Methods
    
    private func extractTitle(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        for line in lines.prefix(10) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 && trimmed.count < 100 {
                return trimmed
            }
        }
        return "Document Analysis"
    }
    
    private func generateSummary(from content: String) -> String {
        let wordCount = content.components(separatedBy: .whitespaces).count
        if content.lowercased().contains("mesoamerica") {
            return "This document covers Mesoamerican civilizations and their historical development before European contact in 1521."
        }
        return "Document contains \(wordCount) words covering various topics for academic study."
    }
    
    private func extractTopics(from content: String) -> [Topic] {
        var topics: [Topic] = []
        let lowerContent = content.lowercased()
        
        // Historical topics
        if lowerContent.contains("mesoamerica") {
            topics.append(Topic(name: "Mesoamerican Civilizations", description: "Pre-Columbian civilizations of Central America", priority: .high, pageReference: "p. 1"))
        }
        if lowerContent.contains("aztec") {
            topics.append(Topic(name: "Aztec Empire", description: "The dominant civilization at the time of Spanish contact", priority: .high, pageReference: "p. 2"))
        }
        if lowerContent.contains("maya") {
            topics.append(Topic(name: "Maya Civilization", description: "Advanced civilization with writing, astronomy, and mathematics", priority: .high, pageReference: "p. 3"))
        }
        if lowerContent.contains("olmec") {
            topics.append(Topic(name: "Olmec Culture", description: "The 'mother culture' of Mesoamerica", priority: .medium, pageReference: "p. 4"))
        }
        
        return topics
    }
    
    private func extractDates(from content: String) -> [HistoricalDate] {
        var dates: [HistoricalDate] = []
        
        if content.contains("1521") {
            dates.append(HistoricalDate(date: "1521", event: "Spanish conquest of the Aztec Empire", significance: "End of independent Mesoamerican civilization", pageReference: "p. 1"))
        }
        if content.contains("1200") {
            dates.append(HistoricalDate(date: "c. 1200 BCE", event: "Rise of Olmec civilization", significance: "Beginning of complex Mesoamerican societies", pageReference: "p. 2"))
        }
        
        return dates
    }
    
    private func extractFigures(from content: String) -> [Person] {
        var figures: [Person] = []
        
        if content.lowercased().contains("moctezuma") {
            figures.append(Person(name: "Moctezuma II", role: "Aztec Emperor", significance: "Ruler during Spanish conquest", timeframe: "1502-1520", pageReference: "p. 3"))
        }
        if content.lowercased().contains("cortés") || content.lowercased().contains("cortes") {
            figures.append(Person(name: "Hernán Cortés", role: "Spanish Conquistador", significance: "Led conquest of Aztec Empire", timeframe: "1519-1521", pageReference: "p. 4"))
        }
        
        return figures
    }
    
    private func extractConcepts(from content: String) -> [Concept] {
        var concepts: [Concept] = []
        
        if content.lowercased().contains("tribute") {
            concepts.append(Concept(name: "Tribute System", definition: "Economic system where conquered peoples provided goods and labor", importance: "Central to Aztec imperial control", relatedConcepts: ["Empire", "Economy"], pageReference: "p. 5"))
        }
        if content.lowercased().contains("calendar") {
            concepts.append(Concept(name: "Mesoamerican Calendar", definition: "Complex system combining solar and ritual calendars", importance: "Reflects advanced astronomical knowledge", relatedConcepts: ["Astronomy", "Religion"], pageReference: "p. 6"))
        }
        
        return concepts
    }
    
    private func generateStudyTasks(from content: String, topics: [Topic]) -> [StudyTask] {
        var tasks: [StudyTask] = []
        
        // Generate tasks based on topics
        for topic in topics {
            switch topic.name {
            case "Mesoamerican Civilizations":
                tasks.append(StudyTask(
                    title: "Map the major Mesoamerican civilizations",
                    description: "Create a geographical and chronological map showing the locations and time periods of major Mesoamerican civilizations",
                    taskType: .understand,
                    estimatedMinutes: 45,
                    priority: .high,
                    pageReference: topic.pageReference,
                    relatedTopics: ["Geography", "Chronology"]
                ))
            case "Aztec Empire":
                tasks.append(StudyTask(
                    title: "Analyze Aztec imperial organization",
                    description: "Study the political, military, and economic structures that allowed the Aztec Empire to control central Mexico",
                    taskType: .analyze,
                    estimatedMinutes: 60,
                    priority: .high,
                    pageReference: topic.pageReference,
                    relatedTopics: ["Politics", "Military", "Economics"]
                ))
            case "Maya Civilization":
                tasks.append(StudyTask(
                    title: "Compare Maya and Aztec achievements",
                    description: "Examine the different accomplishments of Maya and Aztec civilizations in writing, mathematics, and astronomy",
                    taskType: .compare,
                    estimatedMinutes: 50,
                    priority: .medium,
                    pageReference: topic.pageReference,
                    relatedTopics: ["Writing", "Mathematics", "Astronomy"]
                ))
            default:
                tasks.append(StudyTask(
                    title: "Review \(topic.name)",
                    description: "Study the key aspects and significance of \(topic.name)",
                    taskType: .review,
                    estimatedMinutes: 30,
                    priority: .medium,
                    pageReference: topic.pageReference,
                    relatedTopics: [topic.name]
                ))
            }
        }
        
        // Add synthesis task
        if tasks.count > 2 {
            tasks.append(StudyTask(
                title: "Synthesize Mesoamerican cultural patterns",
                description: "Identify common themes and unique characteristics across different Mesoamerican civilizations",
                taskType: .synthesize,
                estimatedMinutes: 40,
                priority: .high,
                pageReference: nil,
                relatedTopics: topics.map { $0.name }
            ))
        }
        
        return tasks
    }
}