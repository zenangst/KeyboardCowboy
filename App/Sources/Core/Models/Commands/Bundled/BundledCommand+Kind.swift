import Foundation

extension BundledCommand {
  enum Kind: Codable, Hashable, Identifiable {
    case assignToWorkspace(command: AssignWorkspaceCommand)
    case moveToWorkspace(command: MoveToWorkspaceCommand)
    case workspace(command: WorkspaceCommand)
    case appFocus(command: AppFocusCommand)
    case tidy(command: WindowTidyCommand)

    var id: String {
      switch self {
      case .appFocus(let appFocus): appFocus.id
      case .assignToWorkspace(let command): command.id
      case .moveToWorkspace(let command): command.id
      case .workspace(let workspace): workspace.id
      case .tidy(let tidy): tidy.id
      }
    }

    func copy() -> Kind {
      switch self {
      case .assignToWorkspace: fatalError("Assignment commands cannot be copied.")
      case .moveToWorkspace: fatalError("Move commands cannot be copied.")
      case .appFocus(let command): .appFocus(command: command.copy())
      case .workspace(let workspace): .workspace(command: workspace.copy())
      case .tidy(let tidy): .tidy(command: tidy.copy())
      }
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BundledCommand.Kind.CodingKeys.self)
      var allKeys = ArraySlice(container.allKeys)
      guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty else {
        throw DecodingError.typeMismatch(BundledCommand.Kind.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Invalid number of keys found, expected one.", underlyingError: nil))
      }
      switch onlyKey {
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
      case .workspace:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.WorkspaceCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.workspace)
        self = BundledCommand.Kind.workspace(command: try nestedContainer.decode(WorkspaceCommand.self, forKey: BundledCommand.Kind.WorkspaceCodingKeys.command))
      case .appFocus:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.AppFocusCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.appFocus)
        self = BundledCommand.Kind.appFocus(command: try nestedContainer.decode(AppFocusCommand.self, forKey: BundledCommand.Kind.AppFocusCodingKeys.command))
      case .tidy:
        let nestedContainer = try container.nestedContainer(keyedBy: BundledCommand.Kind.TidyCodingKeys.self, forKey: BundledCommand.Kind.CodingKeys.tidy)
        self = BundledCommand.Kind.tidy(command: try nestedContainer.decode(WindowTidyCommand.self, forKey: BundledCommand.Kind.TidyCodingKeys.command))
      }
    }
  }
}
