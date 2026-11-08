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

/// Dispatches resolved input to host-supplied insertion implementations.
/// Clipboard ownership and interpolation remain the host's responsibility.
@MainActor
public struct TextExecutor {
  public typealias Insertion = @MainActor (TextExecution) async throws -> Void

  private let typing: Insertion
  private let instant: Insertion

  public init(typing: @escaping Insertion, instant: @escaping Insertion) {
    self.typing = typing
    self.instant = instant
  }

  public func run(_ execution: TextExecution) async throws {
    guard !execution.input.isEmpty else { return }
    switch execution.mode {
    case .typing: try await typing(execution)
    case .instant: try await instant(execution)
    }
  }
}
