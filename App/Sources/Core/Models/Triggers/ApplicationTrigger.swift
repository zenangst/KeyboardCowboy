import Apps
import Foundation

public struct ApplicationTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  public var id: String
  public var application: Application
  public var contexts: Set<Context>

  public init(id: String = UUID().uuidString,
              application: Application,
              contexts: [Context] = []) {
    self.id = id
    self.application = application
    self.contexts = Set(contexts)
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
