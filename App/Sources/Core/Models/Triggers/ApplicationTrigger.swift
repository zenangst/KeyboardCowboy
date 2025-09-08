import Apps
import Foundation

struct ApplicationTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  var id: String
  var application: Application
  var contexts: Set<Context>

  init(id: String = UUID().uuidString,
       application: Application,
       contexts: [Context] = [])
  {
    self.id = id
    self.application = application
    self.contexts = Set(contexts)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let sortedContexts = contexts.sorted(by: { $0.rawValue < $1.rawValue })

    try container.encode(id, forKey: .id)
    try container.encode(application, forKey: .application)
    try container.encode(sortedContexts, forKey: .contexts)
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    return clone
  }

  enum Context: String, Hashable, Codable, CaseIterable, Sendable {
    var id: String { rawValue }

    case closed, launched, frontMost, resignFrontMost

    var displayValue: String {
      switch self {
      case .launched: "Launched"
      case .closed: "Closed"
      case .frontMost: "When in front most"
      case .resignFrontMost: "When backgrounded"
      }
    }
  }
}
