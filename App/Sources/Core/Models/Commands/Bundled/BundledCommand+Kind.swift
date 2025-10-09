import Foundation

extension BundledCommand {
  enum Kind: Codable, Hashable, Identifiable {
    case activatePreviousWorkspace(command: ActivatePreviousWorkspaceCommand)
    case appFocus(command: AppFocusCommand)
    case assignToWorkspace(command: AssignWorkspaceCommand)
    case moveToWorkspace(command: MoveToWorkspaceCommand)
    case tidy(command: WindowTidyCommand)
    case workspace(command: WorkspaceCommand)

    var id: String {
      switch self {
      case let .appFocus(appFocus): appFocus.id
      case let .assignToWorkspace(command): command.id
      case let .moveToWorkspace(command): command.id
      case let .activatePreviousWorkspace(command): command.id
      case let .tidy(tidy): tidy.id
      case let .workspace(workspace): workspace.id
      }
    }

    func copy() -> Kind {
      switch self {
      case let .appFocus(command): .appFocus(command: command.copy())
      case .activatePreviousWorkspace: .activatePreviousWorkspace(command: ActivatePreviousWorkspaceCommand(id: UUID().uuidString))
      case let .tidy(tidy): .tidy(command: tidy.copy())
      case let .workspace(workspace): .workspace(command: workspace.copy())
      case .assignToWorkspace: fatalError("Assignment commands cannot be copied.")
      case .moveToWorkspace: fatalError("Move commands cannot be copied.")
      }
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BundledCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(BundledCommand.Kind.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }

      switch onlyKey {
      case .activatePreviousWorkspace:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.ActivatePreviousWorkspaceCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.activatePreviousWorkspace)
        self = try BundledCommand.Kind.activatePreviousWorkspace(command: nestedContainer.decode(ActivatePreviousWorkspaceCommand.self, forKey: BundledCommand.Kind.ActivatePreviousWorkspaceCodingKeys.command))
      case .appFocus:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.AppFocusCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.appFocus)
        self = try BundledCommand.Kind.appFocus(command: nestedContainer.decode(AppFocusCommand.self, forKey: BundledCommand.Kind.AppFocusCodingKeys.command))
      case .assignToWorkspace:
        let nestedContainer = try container.nestedContainer(
          keyedBy: BundledCommand.Kind.AssignToWorkspaceCodingKeys.self,
          forKey: BundledCommand.Kind.CodingKeys.workspace,
        )
        self = try BundledCommand.Kind.assignToWorkspace(command: nestedContainer.decode(AssignWorkspaceCommand.self, forKey: BundledCommand.Kind.AssignToWorkspaceCodingKeys.command))
      case .moveToWorkspace:
        let nestedContainer = try container.nestedContainer(
          keyedBy: BundledCommand.Kind.MoveToWorkspaceCodingKeys.self,
          forKey: BundledCommand.Kind.CodingKeys.workspace,
        )
        self = try BundledCommand.Kind.moveToWorkspace(command: nestedContainer.decode(MoveToWorkspaceCommand.self, forKey: BundledCommand.Kind.MoveToWorkspaceCodingKeys.command))
      case .tidy:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.TidyCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.tidy)
        self = try BundledCommand.Kind.tidy(command: nestedContainer.decode(WindowTidyCommand.self, forKey: BundledCommand.Kind.TidyCodingKeys.command))
      case .workspace:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.WorkspaceCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.workspace)
        self = try BundledCommand.Kind.workspace(command: nestedContainer.decode(WorkspaceCommand.self, forKey: BundledCommand.Kind.WorkspaceCodingKeys.command))
      }
    }
  }
}
