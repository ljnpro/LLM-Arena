import Foundation

struct LLMServiceFactory {
    static func service(for model: LLMModel, apiKey: String?) -> LLMService? {
        guard let key = apiKey, !key.isEmpty else { return nil }
        switch model {
        case .gpt:
            return OpenAIService(apiKey: key)
        case .gemini:
            return GeminiService(apiKey: key)
        case .grok:
            return GrokService(apiKey: key)
        case .claude:
            return ClaudeService(apiKey: key)
        }
    }
}
