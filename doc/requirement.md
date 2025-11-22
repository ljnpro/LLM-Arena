# Multi-LLM Comparison macOS App – Requirements

## 1. Goal

Build a native macOS app that:

1. Lets the user input and securely store API keys for:
   - OpenAI GPT
   - Google Gemini
   - X Grok
   - Anthropic Claude
2. Sends the same question to all configured models in parallel.
3. Displays all answers in a comparable layout.
4. Asks each model to *review and rate* all models' answers (including its own).
5. Aggregates the ratings, selects the best model, and
6. Uses that best model to generate a final synthesized answer.

This repo is meant to be implemented by an AI coding assistant (e.g., Codex / GPT code model).

---

## 2. Platform & Tech Stack

- Platform: macOS desktop app
- Language: Swift 5+
- UI: SwiftUI (preferred)
- Build: Xcode project, minimum macOS 13 (Ventura)
- Networking: `URLSession`
- Storage: macOS Keychain for API keys

---

## 3. Main Features

1. **API Key Management**
   - Preferences screen for entering:
     - OpenAI GPT API key
     - Google Gemini API key
     - X Grok API key
     - Anthropic Claude API key
   - Save keys in macOS Keychain.
   - Load keys at startup; allow update/delete.

2. **Ask All Models**
   - Main window:
     - Multi-line user question input.
     - Optional shared context input.
     - Button: “Ask All Models”.
   - For each provider with a valid key:
     - Call the model using a shared *Answer Prompt*.
   - Show answers in a 2×2 grid (or dynamic layout if fewer models).

3. **Cross-Review**
   - Button: “Start Cross-Review” (enabled after all answers returned).
   - For each model:
     - Send a *Review Prompt* including:
       - Original question
       - Its own answer
       - All models’ answers (labeled)
   - Expect strict JSON reviews:
     - `ratings[]` with `model`, `score` (0–10), `strengths`, `weaknesses`
     - `best_model`
     - `justification`
   - Parse JSON, aggregate scores, compute:
     - Average score per model
     - Final `winning_model` with deterministic tie-break:
       - GPT > Gemini > Grok > Claude

4. **Final Summary**
   - Call the `winning_model` with a *Final Summary Prompt* including:
     - User question
     - All answers
     - All reviews (raw or summarized JSON)
   - Show the final synthesized answer and:
     - “Selected Best Model: <model>”
     - Average scores per model

5. **Error Handling**
   - Missing API key → model shown as “Not configured” and skipped.
   - Network / API error → show error per model, do not crash.
   - Review JSON parse failure → mark that review invalid, exclude from scoring.

---

## 4. Prompt Templates (high-level)

Implementation should store prompts in code or separate files using these structures:

### 4.1 Answer Prompt

- Inputs:
  - `{model_name}`
  - `{user_question}`
  - `{shared_context}` (optional)

- Behavior:
  - Give a helpful, rigorous answer.
  - Structured output (headings, bullet points).
  - Do **not** mention other models or comparison.

### 4.2 Review Prompt

- Inputs:
  - `{model_name}` (reviewer)
  - `{user_question}`
  - `{your_answer}`
  - `{all_answers_block}` (labeled answers from all models)

- Output:
  - Strict JSON:
    - `ratings[]` with `model`, `score` (0–10), `strengths`, `weaknesses`
    - `best_model`
    - `justification`

### 4.3 Final Summary Prompt

- Inputs:
  - `{winning_model_name}`
  - `{user_question}`
  - `{all_answers_block}`
  - `{all_reviews_json}` (optional)

- Behavior:
  - Synthesize best ideas.
  - Fix errors/omissions.
  - Provide a single, clean, user-focused answer.
  - Do **not** mention internal model comparison.

---

## 5. Implementation Notes

- Use an MVVM-like structure:
  - `View` (SwiftUI)
  - `ViewModel` (state, orchestration)
  - `Service` layer:
    - `OpenAIService`
    - `GeminiService`
    - `GrokService`
    - `ClaudeService`
- All network calls should be asynchronous and run in parallel where possible.
- Keep API keys out of logs; store only in Keychain.
- Aim for code that is easy to extend with more providers.

---

## 6. Tasks for the Coding Assistant

1. Create a new SwiftUI macOS app project.
2. Implement the Keychain-backed settings screen for API keys.
3. Implement services for each provider, with pluggable prompts.
4. Implement the main view:
   - Question input
   - Answer display for each model
   - Cross-review workflow
   - Final summary view
5. Implement score aggregation and model selection logic.
6. Add basic error handling and logging.
