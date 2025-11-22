import SwiftUI

struct AggregateView: View {
    let aggregate: AggregateScores

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aggregate Scores")
                .font(.headline)
            ForEach(aggregate.averages.keys.sorted { $0.tieBreakerRank < $1.tieBreakerRank }, id: \.self) { model in
                HStack {
                    Text(model.displayName)
                    Spacer()
                    Text(String(format: "%.2f", aggregate.averages[model] ?? 0))
                }
            }
            if let winner = aggregate.winningModel {
                Text("Winning Model: \(winner.displayName)")
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
    }
}
