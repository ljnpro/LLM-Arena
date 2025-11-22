import Foundation

final class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    @Published private(set) var keys: [LLMModel: String] = [:]

    private init() {
        loadKeys()
    }

    private func keychainKey(for model: LLMModel) -> String {
        "api.key.\(model.rawValue)"
    }

    func loadKeys() {
        var loaded: [LLMModel: String] = [:]
        for model in LLMModel.allCases {
            if let value = KeychainService.shared.load(key: keychainKey(for: model)) {
                loaded[model] = value
            }
        }
        keys = loaded
    }

    func updateKey(_ value: String, for model: LLMModel) throws {
        try KeychainService.shared.save(key: keychainKey(for: model), value: value)
        keys[model] = value
    }

    func deleteKey(for model: LLMModel) throws {
        try KeychainService.shared.delete(key: keychainKey(for: model))
        keys.removeValue(forKey: model)
    }
}
