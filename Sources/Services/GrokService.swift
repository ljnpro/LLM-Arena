import Foundation

final class GrokService: LLMService {
    let model: LLMModel = .grok
    private let apiKey: String
    private let modelName: String

    init(apiKey: String, modelName: String = "grok-beta") {
        self.apiKey = apiKey
        self.modelName = modelName
    }

    func sendAnswer(question: String, context: String?) async throws -> String {
        let prompt = PromptBuilder.answerPrompt(modelName: model.displayName, question: question, context: context)
        return try await sendChat(prompt: prompt)
    }

    func sendReview(question: String, answers: [LLMModel: String], ownAnswer: String) async throws -> ReviewResult {
        let block = answers.sorted { $0.key.tieBreakerRank < $1.key.tieBreakerRank }
            .map { "\($0.key.displayName):\n\($0.value)" }
            .joined(separator: "\n\n")
        let prompt = PromptBuilder.reviewPrompt(modelName: model.displayName, question: question, yourAnswer: ownAnswer, allAnswersBlock: block)
        let text = try await sendChat(prompt: prompt)
        guard let parsed = ReviewParser.parseReview(text: text, reviewer: model) else {
            throw ServiceError.decodingFailed
        }
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
        return try await sendChat(prompt: prompt)
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private func sendChat(prompt: String) async throws -> String {
        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
            throw ServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ChatRequest(model: modelName, messages: [ChatRequest.Message(role: "user", content: prompt)], temperature: 0.2)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw ServiceError.invalidResponse }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content else { throw ServiceError.invalidResponse }
        return text
    }
}
