import Foundation

enum LLMModel: String, CaseIterable, Identifiable, Codable, Hashable {
    case gpt
    case gemini
    case grok
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt: return "GPT"
        case .gemini: return "Gemini"
        case .grok: return "Grok"
        case .claude: return "Claude"
        }
    }

    var tieBreakerRank: Int {
        switch self {
        case .gpt: return 0
        case .gemini: return 1
        case .grok: return 2
        case .claude: return 3
        }
    }
}
