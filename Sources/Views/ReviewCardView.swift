import SwiftUI

struct ReviewCardView: View {
    let review: ReviewResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reviewer: \(review.reviewer.displayName)")
                .font(.headline)
            if let best = review.bestModel {
                Text("Best Model: \(best.displayName)")
                    .font(.subheadline)
            }
            Text("Justification:")
                .font(.subheadline)
            Text(review.justification)
                .foregroundColor(.secondary)
            Divider()
            Text("Ratings")
                .font(.subheadline.bold())
            ForEach(review.ratings) { rating in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rating.model.displayName)
                        Spacer()
                        Text(String(format: "%.2f", rating.score))
                    }
                    Text("Strengths: \(rating.strengths)")
                        .foregroundColor(.secondary)
                    Text("Weaknesses: \(rating.weaknesses)")
                        .foregroundColor(.secondary)
                }
                Divider()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
    }
}
