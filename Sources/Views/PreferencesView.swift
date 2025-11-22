import SwiftUI

struct PreferencesView: View {
    struct AlertWrapper: Identifiable {
        let id = UUID()
        let message: String
    }

    @ObservedObject var keyManager: APIKeyManager
    @State private var tempKeys: [LLMModel: String] = [:]
    @State private var alertWrapper: AlertWrapper?

    var body: some View {
        Form {
            ForEach(LLMModel.allCases) { model in
                Section(header: Text(model.displayName)) {
                    SecureField("API Key", text: Binding(
                        get: { tempKeys[model] ?? keyManager.keys[model] ?? "" },
                        set: { tempKeys[model] = $0 }
                    ))
                    HStack {
                        Button("Save") { saveKey(for: model) }
                        Button("Delete") { deleteKey(for: model) }
                            .tint(.red)
                    }
                }
            }
        }
        .padding()
        .alert(item: $alertWrapper) { wrapper in
            Alert(title: Text(wrapper.message))
        }
    }

    private func saveKey(for model: LLMModel) {
        do {
            let value = tempKeys[model] ?? keyManager.keys[model] ?? ""
            try keyManager.updateKey(value, for: model)
            alertWrapper = AlertWrapper(message: "Saved key for \(model.displayName).")
        } catch {
            alertWrapper = AlertWrapper(message: "Failed to save: \(error.localizedDescription)")
        }
    }

    private func deleteKey(for model: LLMModel) {
        do {
            try keyManager.deleteKey(for: model)
            tempKeys[model] = ""
            alertWrapper = AlertWrapper(message: "Deleted key for \(model.displayName).")
        } catch {
            alertWrapper = AlertWrapper(message: "Failed to delete: \(error.localizedDescription)")
        }
    }
}
