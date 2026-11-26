/// Insertion settings for input that has already been interpolated by the host.
public struct TextExecution: Sendable, Equatable {
  public enum Mode: String, Codable, Sendable {
    case typing = "Typing"
    case instant = "Instant"
  }

  public enum Action: String, Codable, Hashable, Sendable {
    case insertEnter
  }

  public var input: String
  public var mode: Mode
  public var actions: Set<Action>

  public init(input: String, mode: Mode = .instant, actions: Set<Action> = []) {
    self.input = input
    self.mode = mode
    self.actions = actions
  }
}
