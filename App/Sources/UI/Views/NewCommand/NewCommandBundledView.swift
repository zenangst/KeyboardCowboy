import Bonzai
import SwiftUI

struct NewCommandBundledView: View {
  private static var kinds: [BundledCommand.Kind] {
    [.workspace(WorkspaceCommand(bundleIdentifiers: [], hideOtherApps: true, tiling: nil))]
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
    .menuStyle(.regular)

    VStack(alignment: .leading, spacing: 0) {
      HStack {
        currentSelection.icon
        Text(currentSelection.name)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .leading)

      Divider()

      switch currentSelection {
      case .workspace(let workspaceCommand):
        NewCommandWorkspaceView { tiling in
          currentSelection = .workspace(WorkspaceCommand(
            bundleIdentifiers: workspaceCommand.bundleIdentifiers,
            hideOtherApps: workspaceCommand.hideOtherApps,
            tiling: tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        } onSelectedAppsChange: { selectedApps in
          currentSelection = .workspace(WorkspaceCommand(
            bundleIdentifiers: selectedApps.map(\.application.bundleIdentifier),
            hideOtherApps: workspaceCommand.hideOtherApps,
            tiling: workspaceCommand.tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        } onHideOtherAppsChange: { hideOtherApps in
          currentSelection = .workspace(WorkspaceCommand(
            bundleIdentifiers: workspaceCommand.bundleIdentifiers,
            hideOtherApps: hideOtherApps,
            tiling: workspaceCommand.tiling
          ))
          payload = .bundled(command: BundledCommand(currentSelection, meta: Command.MetaData()))
        }
      }
    }
    .menuStyle(.regular)
    .roundedContainer(padding: 0, margin: 0)
    .onAppear {
      validation = .valid
    }
  }
}


fileprivate extension BundledCommand.Kind {
  var icon: some View {
    switch self {
    case .workspace: WorkspaceIcon(size: 24)
    }
  }

  var name: String {
    switch self {
    case .workspace: "Workspace"
    }
  }
}