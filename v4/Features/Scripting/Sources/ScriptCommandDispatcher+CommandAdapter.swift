import Commands

public extension ScriptCommandDispatcher {
  /// Only the command ID reaches execution. The host applies other metadata.
  func execute(_ command: Command.Script, interpolation: ScriptInterpolation = .init()) async throws -> String? {
    let kind: ScriptRequest.Kind = switch command.kind {
    case .appleScript(variant: .regular): .appleScript(.regular)
    case .appleScript(variant: .jxa): .appleScript(.jxa)
    case .shellScript: .shellScript
    }
    let source: ScriptRequest.Source = switch command.source {
    case let .inline(script): .inline(script)
    case let .path(path): .path(path)
    }
    return try await execute(.init(id: command.id, kind: kind, source: source), interpolation: interpolation)
  }
}
