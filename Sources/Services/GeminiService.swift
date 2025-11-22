import Foundation

final class GeminiService: LLMService {
    let model: LLMModel = .gemini
    private let apiKey: String
    private let modelName: String

    init(apiKey: String, modelName: String = "gemini-1.5-flash") {
        self.apiKey = apiKey
        self.modelName = modelName
    }

    func sendAnswer(question: String, context: String?) async throws -> String {
        let prompt = PromptBuilder.answerPrompt(modelName: model.displayName, question: question, context: context)
        return try await sendContent(prompt: prompt)
    }

    func sendReview(question: String, answers: [LLMModel: String], ownAnswer: String) async throws -> ReviewResult {
        let block = answers.sorted { $0.key.tieBreakerRank < $1.key.tieBreakerRank }
            .map { "\($0.key.displayName):\n\($0.value)" }
            .joined(separator: "\n\n")
        let prompt = PromptBuilder.reviewPrompt(modelName: model.displayName, question: question, yourAnswer: ownAnswer, allAnswersBlock: block)
        let text = try await sendContent(prompt: prompt)
        guard let parsed = ReviewParser.parseReview(text: text, reviewer: model) else { throw ServiceError.decodingFailed }
        return parsed
    }

    func sendFinalSummary(question: String, answers: [LLMModel: String], reviews: [LLMModel: ReviewResult]) async throws -> String {
        let answersBlock = answers.sorted { $0.key.tieBreakerRank < $1.key.tieBreakerRank }
            .map { "\($0.key.displayName):\n\($0.value)" }
            .joined(separator: "\n\n")
        let reviewsJSON: String
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(reviews.map { $0.value })
            reviewsJSON = String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            reviewsJSON = "[]"
        }
        let prompt = PromptBuilder.finalSummaryPrompt(winningModel: model.displayName, question: question, answersBlock: answersBlock, reviewsJSON: reviewsJSON)
        return try await sendContent(prompt: prompt)
    }

    private struct GeminiRequest: Encodable {
        struct Content: Encodable {
            struct Part: Encodable {
                let text: String
            }
            let parts: [Part]
        }
        let contents: [Content]
    }

    private struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String? }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }

    private func sendContent(prompt: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)") else {
            throw ServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = GeminiRequest(contents: [GeminiRequest.Content(parts: [GeminiRequest.Content.Part(text: prompt)])])
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ServiceError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.compactMap({ $0.text }).joined(separator: "\n"), !text.isEmpty else {
            throw ServiceError.invalidResponse
        }
        return text
    }
}
