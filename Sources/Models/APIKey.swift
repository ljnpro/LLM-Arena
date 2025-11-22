import Foundation

struct APIKey: Identifiable, Codable, Hashable {
    let id: UUID
    let model: LLMModel
    var value: String

    init(model: LLMModel, value: String) {
        self.id = UUID()
        self.model = model
        self.value = value
    }
}
