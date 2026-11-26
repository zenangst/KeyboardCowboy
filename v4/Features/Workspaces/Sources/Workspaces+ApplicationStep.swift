import ApplicationCatalog
import Commands

public extension Workspaces {
  struct ApplicationStep: Equatable, Sendable {
    public let application: ApplicationCatalog.Application
    public let name: String
    public let action: Command.Application.Action
    public let modifiers: Set<Command.Application.Modifier>
  }
}
