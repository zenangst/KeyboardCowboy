import Apps
import Bonzai
import SwiftUI

struct NewCommandBundledView: View {
  private static var kinds: [BundledCommand.Kind] {
    [
      .appFocus(command: AppFocusCommand(bundleIdentifer: "", hideOtherApps: false,
                                tiling: nil, createNewWindow: true)),
      .workspace(
        command: WorkspaceCommand(
          applications: [],
          defaultForDynamicWorkspace: false,
          hideOtherApps: true,
          tiling: nil
        )
      ),
      .tidy(command: WindowTidyCommand(rules: []))
    ]
  }
  private let kinds: [BundledCommand.Kind]

  @Binding private var payload: NewCommandPayload
  @Binding private var validation: NewCommandValidation
  @State private var currentSelection: BundledCommand.Kind

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
    self.kinds = Self.kinds
    self.currentSelection = Self.kinds.first!
  }

  var body: some View {
    HStack {
      Text("Command")
      Menu {
        ForEach(kinds) { kind in
          Button(action: { currentSelection = kind },
                 label: { Text(kind.name) })
        }
      } label: {
        Text(currentSelection.name)
      }
    }

    VStack(alignment: .leading, spacing: 0) {
      HStack {
        currentSelection.icon
        Text(currentSelection.name)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .leading)

      Divider()

      switch currentSelection {
      case .assignToWorkspace, .moveToWorkspace, .activatePreviousWorkspace: fatalError()
      case .appFocus(let command):
        NewCommandAppFocusView(validation: $validation) { tiling in
          currentSelection = .appFocus(
            command: AppFocusCommand(bundleIdentifer: command.bundleIdentifer,
                              hideOtherApps: command.hideOtherApps,
                              tiling: tiling,
                              createNewWindow: command.createNewWindow)
          )
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        } onSelectedAppsChange: { bundleIdentifier in
          currentSelection = .appFocus(
            command: AppFocusCommand(bundleIdentifer: bundleIdentifier,
                              hideOtherApps: command.hideOtherApps,
                              tiling: command.tiling,
                              createNewWindow: command.createNewWindow)
          )
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
          validation = updateAndValidatePayload()
        } onHideOtherAppsChange: { hideOtherApps in
          currentSelection = .appFocus(
            command: AppFocusCommand(bundleIdentifer: command.bundleIdentifer,
                              hideOtherApps: hideOtherApps,
                              tiling: command.tiling,
                              createNewWindow: command.createNewWindow)
          )
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        } onCreateNewWindowChange: { createWindow in
          currentSelection = .appFocus(
            command: AppFocusCommand(bundleIdentifer: command.bundleIdentifer,
                              hideOtherApps: command.hideOtherApps,
                              tiling: command.tiling,
                              createNewWindow: createWindow)
          )
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        }
      case .workspace(let workspaceCommand):
        NewCommandWorkspaceView(validation: $validation) { tiling in
          currentSelection = .workspace(command: WorkspaceCommand(
            applications: workspaceCommand.applications,
            defaultForDynamicWorkspace: workspaceCommand.defaultForDynamicWorkspace,
            hideOtherApps: workspaceCommand.hideOtherApps,
            tiling: tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        } onSelectedAppsChange: { selectedApps in
          currentSelection = .workspace(command: WorkspaceCommand(
            applications: selectedApps.map { WorkspaceCommand.WorkspaceApplication(bundleIdentifier: $0.application.bundleIdentifier, options: []) },
            defaultForDynamicWorkspace: workspaceCommand.defaultForDynamicWorkspace,
            hideOtherApps: workspaceCommand.hideOtherApps,
            tiling: workspaceCommand.tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
          validation = updateAndValidatePayload()
        } onHideOtherAppsChange: { hideOtherApps in
          currentSelection = .workspace(command: WorkspaceCommand(
            applications: workspaceCommand.applications,
            defaultForDynamicWorkspace: workspaceCommand.defaultForDynamicWorkspace,
            hideOtherApps: hideOtherApps,
            tiling: workspaceCommand.tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        }
      case .tidy:
        NewCommandTidyView(validation: $validation) { rules in
          let rules = rules.map { WindowTidyCommand.Rule(bundleIdentifier: $0.application.bundleIdentifier, tiling: $0.tiling) }
          currentSelection = .tidy(command: WindowTidyCommand(id: UUID().uuidString, rules: rules))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        }
      }
    }
    .roundedStyle(padding: 0)
    .onChange(of: validation) { newValue in
      guard newValue == .needsValidation else { return }
      validation = updateAndValidatePayload()
    }
    .onAppear {
      validation = .unknown
    }
  }

  @discardableResult
  private func updateAndValidatePayload() -> NewCommandValidation {
    switch currentSelection {
    case .assignToWorkspace, .moveToWorkspace, .activatePreviousWorkspace: fatalError()
    case .workspace(let workspaceCommand):
      if workspaceCommand.applications.isEmpty {
        return .invalid(reason: "Pick at least one application.")
      }
    case .appFocus(let appFocusCommand):
      if appFocusCommand.bundleIdentifer.isEmpty {
        return .invalid(reason: "Pick an application.")
      }
    case .tidy:
      return .valid
    }

    return .valid
  }
}


fileprivate extension BundledCommand.Kind {
  @ViewBuilder
  var icon: some View {
    switch self {
    case .activatePreviousWorkspace: WorkspaceIcon(.activatePrevious, size: 24)
    case .appFocus: AppFocusIcon(size: 24)
    case .workspace(let workspace): WorkspaceIcon(workspace.isDynamic ? .dynamic : .regular, size: 24)
    case .tidy: WindowTidyIcon(size: 24)
    case .assignToWorkspace, .moveToWorkspace: fatalError()
    }
  }

  var name: String {
    switch self {
    case .assignToWorkspace, .moveToWorkspace: fatalError()
    case .activatePreviousWorkspace: "Activate Previous Workspace"
    case .appFocus: "Focus on Application"
    case .tidy: "Tidy up Windows"
    case .workspace: "Workspace"
    }
  }
}
