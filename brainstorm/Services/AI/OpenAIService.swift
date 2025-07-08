//
//  OpenAIService.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import Foundation

@MainActor
class OpenAIService: AIAnalysisService {
    var serviceName: String = "OpenAI GPT-4"
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4o" // Latest model with document analysis capabilities
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func isAvailable() -> Bool {
        return !apiKey.isEmpty
    }
    
    func analyzeDocument(_ content: String, title: String?) async throws -> DocumentAnalysis {
        let prompt = createAnalysisPrompt(content: content, title: title)
        
        let messages = [
            ["role": "system", "content": "You are an expert academic document analyzer. Analyze the provided document and generate structured study materials. Focus on creating actionable study tasks, not just summaries."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 4000
        ]
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.apiError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIServiceError.parsingError("Failed to encode request: \(error)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError("API request failed (\(httpResponse.statusCode)): \(errorMessage)")
        }
        
        do {
            let apiResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = apiResponse?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIServiceError.parsingError("Invalid API response structure")
            }
            
            return try parseAnalysisResponse(content, originalTitle: title)
        } catch {
            throw AIServiceError.parsingError("Failed to parse response: \(error)")
        }
    }
    
    func generateStudyTasks(_ analysis: DocumentAnalysis) async throws -> [StudyTask] {
        // The study tasks are already generated in the main analysis
        return analysis.studyTasks
    }
    
    // MARK: - Private Methods
    
    private func createAnalysisPrompt(content: String, title: String?) -> String {
        return """
        Please analyze this academic document and provide a comprehensive study analysis. Return your response in the following JSON format:

        {
          "title": "Document title",
          "summary": "2-3 sentence summary of the main content",
          "mainTopics": [
            {
              "name": "Topic name",
              "description": "Brief description",
              "priority": "high|medium|low",
              "pageReference": "p. X"
            }
          ],
          "studyTasks": [
            {
              "title": "Actionable study task",
              "description": "What the student should do",
              "taskType": "memorize|understand|analyze|compare|synthesize|review",
              "estimatedMinutes": 30,
              "priority": "high|medium|low",
              "pageReference": "p. X",
              "relatedTopics": ["topic1", "topic2"]
            }
          ],
          "keyDates": [
            {
              "date": "Date or period",
              "event": "What happened",
              "significance": "Why it matters",
              "pageReference": "p. X"
            }
          ],
          "importantFigures": [
            {
              "name": "Person name",
              "role": "Their role/position",
              "significance": "Why they're important",
              "timeframe": "When they lived/were active",
              "pageReference": "p. X"
            }
          ],
          "concepts": [
            {
              "name": "Concept name",
              "definition": "Clear definition",
              "importance": "Why it's significant",
              "relatedConcepts": ["concept1", "concept2"],
              "pageReference": "p. X"
            }
          ]
        }

        Focus on creating actionable study tasks that help students learn and understand the material, not just read it. Each task should be specific and measurable.

        Document title: \(title ?? "Unknown")
        
        Document content:
        \(content)
        """
    }
    
    private func parseAnalysisResponse(_ responseContent: String, originalTitle: String?) throws -> DocumentAnalysis {
        // First, try to extract JSON from the response
        guard let jsonData = extractJSON(from: responseContent) else {
            throw AIServiceError.parsingError("No valid JSON found in response")
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenAIAnalysisResponse.self, from: jsonData)
            
            // Convert to our DocumentAnalysis format
            let topics = response.mainTopics.map { topic in
                Topic(
                    name: topic.name,
                    description: topic.description,
                    priority: Topic.Priority(rawValue: topic.priority) ?? .medium,
                    pageReference: topic.pageReference
                )
            }
            
            let studyTasks = response.studyTasks.map { task in
                StudyTask(
                    title: task.title,
                    description: task.description,
                    taskType: StudyTask.TaskType(rawValue: task.taskType) ?? .understand,
                    estimatedMinutes: task.estimatedMinutes,
                    priority: StudyTask.Priority(rawValue: task.priority) ?? .medium,
                    pageReference: task.pageReference,
                    relatedTopics: task.relatedTopics
                )
            }
            
            let keyDates = response.keyDates.map { date in
                HistoricalDate(
                    date: date.date,
                    event: date.event,
                    significance: date.significance,
                    pageReference: date.pageReference
                )
            }
            
            let figures = response.importantFigures.map { figure in
                Person(
                    name: figure.name,
                    role: figure.role,
                    significance: figure.significance,
                    timeframe: figure.timeframe,
                    pageReference: figure.pageReference
                )
            }
            
            let concepts = response.concepts.map { concept in
                Concept(
                    name: concept.name,
                    definition: concept.definition,
                    importance: concept.importance,
                    relatedConcepts: concept.relatedConcepts,
                    pageReference: concept.pageReference
                )
            }
            
            return DocumentAnalysis(
                title: response.title.isEmpty ? (originalTitle ?? "Document Analysis") : response.title,
                summary: response.summary,
                mainTopics: topics,
                studyTasks: studyTasks,
                keyDates: keyDates,
                importantFigures: figures,
                concepts: concepts
            )
        } catch {
            throw AIServiceError.parsingError("Failed to decode JSON response: \(error)")
        }
    }
    
    private func extractJSON(from text: String) -> Data? {
        // Look for JSON between ```json and ``` or just find the first { to last }
        if let startRange = text.range(of: "{"),
           let endRange = text.range(of: "}", options: .backwards) {
            let jsonString = String(text[startRange.lowerBound...endRange.upperBound])
            return jsonString.data(using: .utf8)
        }
        return nil
    }
}

// MARK: - Response Models

private struct OpenAIAnalysisResponse: Codable {
    let title: String
    let summary: String
    let mainTopics: [OpenAITopic]
    let studyTasks: [OpenAIStudyTask]
    let keyDates: [OpenAIHistoricalDate]
    let importantFigures: [OpenAIPerson]
    let concepts: [OpenAIConcept]
}

private struct OpenAITopic: Codable {
    let name: String
    let description: String
    let priority: String
    let pageReference: String?
}

private struct OpenAIStudyTask: Codable {
    let title: String
    let description: String
    let taskType: String
    let estimatedMinutes: Int
    let priority: String
    let pageReference: String?
    let relatedTopics: [String]
}

private struct OpenAIHistoricalDate: Codable {
    let date: String
    let event: String
    let significance: String
    let pageReference: String?
}

private struct OpenAIPerson: Codable {
    let name: String
    let role: String
    let significance: String
    let timeframe: String?
    let pageReference: String?
}

private struct OpenAIConcept: Codable {
    let name: String
    let definition: String
    let importance: String
    let relatedConcepts: [String]
    let pageReference: String?
}