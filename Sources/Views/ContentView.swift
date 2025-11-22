import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    inputSection
                    actionButtons
                    answerGrid
                    reviewSection
                    finalSummarySection
                }
                .padding()
            }
            .navigationTitle("Multi-LLM Comparison")
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("User Question")
                .font(.headline)
            TextEditor(text: $viewModel.question)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            Text("Shared Context (optional)")
                .font(.headline)
            TextEditor(text: $viewModel.sharedContext)
                .frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.askAllModels) {
                Label("Ask All Models", systemImage: "paperplane")
            }
            .disabled(viewModel.isAskingAll || viewModel.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button(action: viewModel.startCrossReview) {
                Label("Start Cross-Review", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(!viewModel.canStartReview() || viewModel.isReviewing)

            Button(action: viewModel.startFinalSummary) {
                Label("Final Summary", systemImage: "star.fill")
            }
            .disabled(viewModel.aggregateScores?.winningModel == nil || viewModel.isSummarizing)

            Spacer()
        }
    }

    private var answerGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Answers")
                    .font(.title2)
                if viewModel.isAskingAll { ProgressView() }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(LLMModel.allCases) { model in
                    AnswerCardView(model: model, status: viewModel.answerStatus[model] ?? .idle, answer: viewModel.answers[model])
                }
            }
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cross-Review")
                    .font(.title2)
                if viewModel.isReviewing { ProgressView() }
            }
            if viewModel.reviews.isEmpty {
                Text("Run cross-review after all answers are ready.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.reviews.keys.sorted { $0.tieBreakerRank < $1.tieBreakerRank }, id: \.self) { model in
                    if let review = viewModel.reviews[model] {
                        ReviewCardView(review: review)
                    }
                }
                if let aggregate = viewModel.aggregateScores {
                    AggregateView(aggregate: aggregate)
                }
            }
        }
    }

    private var finalSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Final Summary")
                    .font(.title2)
                if viewModel.isSummarizing { ProgressView() }
            }
            if let aggregate = viewModel.aggregateScores, let winner = aggregate.winningModel {
                Text("Selected Best Model: \(winner.displayName)")
                    .font(.headline)
                if !aggregate.averages.isEmpty {
                    ForEach(aggregate.averages.keys.sorted { $0.tieBreakerRank < $1.tieBreakerRank }, id: \.self) { model in
                        let score = aggregate.averages[model] ?? 0
                        Text("\(model.displayName): \(String(format: "%.2f", score))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            if !viewModel.finalSummary.isEmpty {
                Text(viewModel.finalSummary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: AppViewModel())
    }
}
