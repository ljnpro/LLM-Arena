import SwiftUI

struct AnswerCardView: View {
    let model: LLMModel
    let status: AnswerStatus
    let answer: AnswerResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.displayName)
                    .font(.headline)
                Spacer()
                statusView
            }
            Divider()
            contentView
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .idle:
            Text("Idle").foregroundColor(.secondary)
        case .loading:
            ProgressView()
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .skipped(let message):
            Text(message).foregroundColor(.secondary).font(.footnote)
        case .error(let error):
            Text(error).foregroundColor(.red).font(.footnote)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch status {
        case .success:
            if let text = answer?.text {
                ScrollView {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120)
            }
        case .skipped(let message):
            Text(message)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .idle:
            Text("Awaiting request")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .loading:
            Text("Requesting...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
