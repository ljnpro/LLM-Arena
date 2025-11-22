import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var sharedContext: String = ""
    @Published var answers: [LLMModel: AnswerResult] = [:]
    @Published var answerStatus: [LLMModel: AnswerStatus] = [:]
    @Published var reviews: [LLMModel: ReviewResult] = [:]
    @Published var aggregateScores: AggregateScores?
    @Published var finalSummary: String = ""
    @Published var isAskingAll = false
    @Published var isReviewing = false
    @Published var isSummarizing = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        APIKeyManager.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        LLMModel.allCases.forEach { answerStatus[$0] = .idle }
    }

    func apiKey(for model: LLMModel) -> String? {
        APIKeyManager.shared.keys[model]
    }

    func askAllModels() {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isAskingAll = true
        answers = [:]
        reviews = [:]
        aggregateScores = nil
        finalSummary = ""
        LLMModel.allCases.forEach { model in
            if apiKey(for: model) == nil {
                answerStatus[model] = .skipped("Not configured")
            } else {
                answerStatus[model] = .loading
            }
        }

        Task {
            await withTaskGroup(of: (LLMModel, Result<String, Error>).self) { group in
                for model in LLMModel.allCases {
                    guard let service = LLMServiceFactory.service(for: model, apiKey: apiKey(for: model)) else { continue }
                    let q = question
                    let ctx = sharedContext
                    group.addTask {
                        do {
                            let text = try await service.sendAnswer(question: q, context: ctx)
                            return (model, .success(text))
                        } catch {
                            return (model, .failure(error))
                        }
                    }
                }

                for await result in group {
                    switch result.1 {
                    case .success(let text):
                        answers[result.0] = AnswerResult(model: result.0, text: text)
                        answerStatus[result.0] = .success
                    case .failure(let error):
                        answerStatus[result.0] = .error(error.localizedDescription)
                    }
                }
            }
            isAskingAll = false
        }
    }

    func canStartReview() -> Bool {
        !answers.isEmpty && !isAskingAll
    }

    func startCrossReview() {
        guard canStartReview() else { return }
        isReviewing = true
        reviews = [:]
        aggregateScores = nil

        Task {
            await withTaskGroup(of: (LLMModel, Result<ReviewResult, Error>).self) { group in
                for (model, answer) in answers {
                    guard let service = LLMServiceFactory.service(for: model, apiKey: apiKey(for: model)) else { continue }
                    let q = question
                    let ansDict = answers.mapValues { $0.text }
                    group.addTask {
                        do {
                            let review = try await service.sendReview(question: q, answers: ansDict, ownAnswer: answer.text)
                            return (model, .success(review))
                        } catch {
                            return (model, .failure(error))
                        }
                    }
                }

                for await result in group {
                    switch result.1 {
                    case .success(let review):
                        reviews[result.0] = review
                    case .failure:
                        continue
                    }
                }
            }
            aggregateScores = computeAggregate()
            isReviewing = false
        }
    }

    private func computeAggregate() -> AggregateScores {
        var totals: [LLMModel: [Double]] = [:]
        for review in reviews.values {
            for rating in review.ratings {
                totals[rating.model, default: []].append(rating.score)
            }
        }
        var averages: [LLMModel: Double] = [:]
        for (model, scores) in totals {
            let avg = scores.reduce(0, +) / Double(scores.count)
            averages[model] = avg
        }
        let winning = averages.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.tieBreakerRank < rhs.key.tieBreakerRank
            }
            return lhs.value > rhs.value
        }.first?.key
        return AggregateScores(averages: averages, winningModel: winning)
    }

    func startFinalSummary() {
        guard let aggregate = aggregateScores, let winner = aggregate.winningModel else { return }
        guard let service = LLMServiceFactory.service(for: winner, apiKey: apiKey(for: winner)) else { return }
        isSummarizing = true
        Task {
            do {
                let summary = try await service.sendFinalSummary(question: question, answers: answers.mapValues { $0.text }, reviews: reviews)
                finalSummary = summary
            } catch {
                errorMessage = error.localizedDescription
            }
            isSummarizing = false
        }
    }
}
