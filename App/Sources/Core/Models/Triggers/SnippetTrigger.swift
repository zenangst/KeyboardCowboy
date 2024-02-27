import Foundation

struct SnippetTrigger: Identifiable, Hashable, Codable, Equatable {
  let id: String
  let text: String

  func copy() -> Self {
    SnippetTrigger(id: UUID().uuidString, text: text)
  }
}
