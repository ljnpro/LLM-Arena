import Foundation

struct ReviewRating: Identifiable, Codable, Hashable {
    let id: UUID
    let model: LLMModel
    let score: Double
    let strengths: String
    let weaknesses: String

    init(model: LLMModel, score: Double, strengths: String, weaknesses: String) {
        self.id = UUID()
        self.model = model
        self.score = score
        self.strengths = strengths
        self.weaknesses = weaknesses
    }
}

struct ReviewResult: Identifiable, Codable, Hashable {
    let id: UUID
    let reviewer: LLMModel
    let ratings: [ReviewRating]
    let bestModel: LLMModel?
    let justification: String

    init(reviewer: LLMModel, ratings: [ReviewRating], bestModel: LLMModel?, justification: String) {
        self.id = UUID()
        self.reviewer = reviewer
        self.ratings = ratings
        self.bestModel = bestModel
        self.justification = justification
    }
}

struct AggregateScores {
    let averages: [LLMModel: Double]
    let winningModel: LLMModel?
}
