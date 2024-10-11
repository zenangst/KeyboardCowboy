import Apps
import Foundation

struct ApplicationTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  var id: String
  var application: Application
  var contexts: Set<Context>

  init(id: String = UUID().uuidString,
       application: Application,
       contexts: [Context] = []) {
    self.id = id
    self.application = application
    self.contexts = Set(contexts)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    #warning("Make this into an extension on RawRepresentable?")
    let sortedContexts = self.contexts.sorted(by: { $0.rawValue < $1.rawValue  })

    try container.encode(self.id, forKey: .id)
    try container.encode(self.application, forKey: .application)
    try container.encode(sortedContexts, forKey: .contexts)
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    return clone
  }

  public enum Context: String, Hashable, Codable, CaseIterable, Sendable {
    public var id: String { rawValue }

    case closed, launched, frontMost, resignFrontMost

    public var displayValue: String {
      switch self {
      case .launched:        "Launched"
      case .closed:          "Closed"
      case .frontMost:       "When in front most"
      case .resignFrontMost: "When backgrounded"
      }
    }
  }
}
