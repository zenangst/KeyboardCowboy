import Apps
import Foundation

public struct ApplicationTrigger: Hashable, Identifiable, Codable, Sendable {
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

  public enum Context: String, Toggleable, Hashable, Codable, CaseIterable, Sendable {
    public var id: String { rawValue }

    case closed, launched, frontMost

    public var displayValue: String {
      switch self {
      case .launched:
        return "Launched"
      case .closed:
        return "Closed"
      case .frontMost:
        return "When in front most"
      }
    }
  }
}
