import Foundation

struct PromptBuilder {
    static func answerPrompt(modelName: String, question: String, context: String?) -> String {
        let contextBlock = (context ?? "").isEmpty ? "(none provided)" : (context ?? "")
        return """
You are \(modelName). Provide a helpful, rigorous answer for the user.

User Question:
\(question)

Shared Context (optional):
\(contextBlock)

Requirements:
- Give a structured, easy-to-read answer with headings and bullet points when useful.
- Do not mention other models or any comparison language.
"""
    }

    static func reviewPrompt(modelName: String, question: String, yourAnswer: String, allAnswersBlock: String) -> String {
        return """
You are \(modelName). Review the following answers to the user's question and provide strict JSON only.

User Question:
\(question)

Your Answer:
\(yourAnswer)

All Model Answers:
\(allAnswersBlock)

Respond with STRICT JSON using this schema:
{
  \"ratings\": [
    {
      \"model\": \"GPT|Gemini|Grok|Claude\",
      \"score\": 0-10 number,
      \"strengths\": \"string\",
      \"weaknesses\": \"string\"
    }
  ],
  \"best_model\": \"GPT|Gemini|Grok|Claude\",
  \"justification\": \"string\"
}
Return only JSON, no prose.
"""
    }

    static func finalSummaryPrompt(winningModel: String, question: String, answersBlock: String, reviewsJSON: String) -> String {
        return """
You are \(winningModel), selected as the best reviewer. Create the final synthesized answer for the user.

User Question:
\(question)

All Model Answers:
\(answersBlock)

All Review JSON:
\(reviewsJSON)

Task:
- Synthesize the best ideas from all answers.
- Correct any errors or omissions.
- Provide a single, concise answer focused entirely on the user question.
- Do not mention model comparisons or internal process.
"""
    }
}
