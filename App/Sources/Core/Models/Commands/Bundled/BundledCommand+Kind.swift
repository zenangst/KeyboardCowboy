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
      case .appFocus(let appFocus): appFocus.id
      case .assignToWorkspace(let command): command.id
      case .moveToWorkspace(let command): command.id
      case .activatePreviousWorkspace(let command): command.id
      case .tidy(let tidy): tidy.id
      case .workspace(let workspace): workspace.id
      }
    }

    func copy() -> Kind {
      switch self {
        case .appFocus(let command): .appFocus(command: command.copy())
        case .activatePreviousWorkspace: .activatePreviousWorkspace(command: ActivatePreviousWorkspaceCommand(id: UUID().uuidString))
        case .tidy(let tidy): .tidy(command: tidy.copy())
        case .workspace(let workspace): .workspace(command: workspace.copy())
        case .assignToWorkspace: fatalError("Assignment commands cannot be copied.")
        case .moveToWorkspace: fatalError("Move commands cannot be copied.")
      }
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BundledCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(BundledCommand.Kind.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }
      switch onlyKey {
      case .activatePreviousWorkspace:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.ActivatePreviousWorkspaceCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.activatePreviousWorkspace)
        self = BundledCommand.Kind.activatePreviousWorkspace(command: try nestedContainer.decode(ActivatePreviousWorkspaceCommand.self, forKey: BundledCommand.Kind.ActivatePreviousWorkspaceCodingKeys.command))
      case .appFocus:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.AppFocusCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.appFocus)
        self = BundledCommand.Kind.appFocus(command: try nestedContainer.decode(AppFocusCommand.self, forKey: BundledCommand.Kind.AppFocusCodingKeys.command))
      case .assignToWorkspace:
        let nestedContainer = try container.nestedContainer(
          keyedBy: BundledCommand.Kind.AssignToWorkspaceCodingKeys.self,
          forKey: BundledCommand.Kind.CodingKeys.workspace
        )
        self = BundledCommand.Kind.assignToWorkspace(command: try nestedContainer.decode(AssignWorkspaceCommand.self, forKey: BundledCommand.Kind.AssignToWorkspaceCodingKeys.command))
      case .moveToWorkspace:
        let nestedContainer = try container.nestedContainer(
          keyedBy: BundledCommand.Kind.MoveToWorkspaceCodingKeys.self,
          forKey: BundledCommand.Kind.CodingKeys.workspace
        )
        self = BundledCommand.Kind.moveToWorkspace(command: try nestedContainer.decode(MoveToWorkspaceCommand.self, forKey: BundledCommand.Kind.MoveToWorkspaceCodingKeys.command))
      case .tidy:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.TidyCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.tidy)
        self = BundledCommand.Kind.tidy(command: try nestedContainer.decode(WindowTidyCommand.self, forKey: BundledCommand.Kind.TidyCodingKeys.command))
      case .workspace:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.WorkspaceCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.workspace)
        self = BundledCommand.Kind.workspace(command: try nestedContainer.decode(WorkspaceCommand.self, forKey: BundledCommand.Kind.WorkspaceCodingKeys.command))
      }
    }
  }
}
