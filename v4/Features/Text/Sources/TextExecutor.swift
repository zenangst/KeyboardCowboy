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
