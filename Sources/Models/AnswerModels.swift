import Foundation

enum AnswerStatus: Equatable {
    case idle
    case loading
    case success
    case error(String)
    case skipped(String)
}

struct AnswerResult: Identifiable, Codable, Hashable {
    let id: UUID
    let model: LLMModel
    let text: String
    let timestamp: Date

    init(model: LLMModel, text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.model = model
        self.text = text
        self.timestamp = timestamp
    }
}
