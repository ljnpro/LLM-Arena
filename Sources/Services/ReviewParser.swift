import Foundation

struct ReviewJSON: Codable {
    struct Rating: Codable {
        let model: String
        let score: Double
        let strengths: String
        let weaknesses: String
    }
    let ratings: [Rating]
    let best_model: String?
    let justification: String
}

struct ReviewParser {
    static func parseReview(text: String, reviewer: LLMModel) -> ReviewResult? {
        guard let data = text.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(ReviewJSON.self, from: data) else {
            return nil
        }
        let ratings: [ReviewRating] = decoded.ratings.compactMap { rating in
            guard let model = LLMModel(rawValue: rating.model.lowercased()) ?? modelFromDisplay(rating.model) else { return nil }
            return ReviewRating(model: model, score: rating.score, strengths: rating.strengths, weaknesses: rating.weaknesses)
        }
        let bestModel = decoded.best_model.flatMap { LLMModel(rawValue: $0.lowercased()) ?? modelFromDisplay($0) }
        return ReviewResult(reviewer: reviewer, ratings: ratings, bestModel: bestModel, justification: decoded.justification)
    }

    private static func modelFromDisplay(_ value: String) -> LLMModel? {
        switch value.lowercased() {
        case "gpt", "openai": return .gpt
        case "gemini", "google": return .gemini
        case "grok": return .grok
        case "claude", "anthropic": return .claude
        default: return nil
        }
    }
}
