import Foundation

protocol LLMService {
    var model: LLMModel { get }
    func sendAnswer(question: String, context: String?) async throws -> String
    func sendReview(question: String, answers: [LLMModel: String], ownAnswer: String) async throws -> ReviewResult
    func sendFinalSummary(question: String, answers: [LLMModel: String], reviews: [LLMModel: ReviewResult]) async throws -> String
}

enum ServiceError: Error, LocalizedError {
    case missingKey
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "API key missing"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}
