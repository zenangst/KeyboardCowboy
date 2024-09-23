import Apps
import Bonzai
import SwiftUI

struct NewCommandWorkspaceView: View {
  @EnvironmentObject private var applicationStore: ApplicationStore
  @State private var tiling: WorkspaceCommand.Tiling?
  @State private var selectedApps = [WorkspaceApplicationItem]()
  @State private var hideOtherApps = true

  private let onTilingChange: (WorkspaceCommand.Tiling?) -> Void
  private let onSelectedAppsChange: ([WorkspaceApplicationItem]) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void

  init(onTilingChange: @escaping (WorkspaceCommand.Tiling?) -> Void,
       onSelectedAppsChange: @escaping ([WorkspaceApplicationItem]) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void) {
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Applications")
        .font(.subheadline)
      VStack(spacing: 0) {
        Menu {
          ForEach(applicationStore.applications) { application in
            Button(action: {
              selectedApps.append(WorkspaceApplicationItem(application))
              onSelectedAppsChange(selectedApps)
            },
                   label: { Text(application.displayName) })
          }
        } label: {
          Text("Add Application")
        }
        .menuStyle(.regular)
        .padding(4)

        List {
          ForEach(Array(zip(selectedApps.indices, selectedApps)), id: \.0) { offset, item in
            HStack {
              IconView(icon: Icon.init(item.application), size: CGSize(width: 18, height: 18))
              Text(item.application.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)
              Button {
                if offset <= selectedApps.count - 1 {
                  let selectedApp = selectedApps[offset]
                  if item.application == selectedApp.application {
                    selectedApps.remove(at: offset)
                    onSelectedAppsChange(selectedApps)
                  }
                }
              } label: {
                Text("Remove")
                  .font(.caption)
              }
              .buttonStyle(.destructive)
            }
            .padding([.horizontal, .bottom], 4)
          }
          .onMove { indexSet, offset in
            selectedApps.move(fromOffsets: indexSet, toOffset: offset)
            onSelectedAppsChange(selectedApps)
          }
        }
      }
      .roundedContainer(padding: 0, margin: 0)
      .padding(.bottom)

      HStack {
        VStack(alignment: .leading) {
          Text("Tiling")
            .font(.subheadline)

          Menu {
            ForEach(WorkspaceCommand.Tiling.allCases) { tiling in
              Button {
                self.tiling = tiling
                onTilingChange(tiling)
              } label: {
                Text(tiling.name)
              }
            }
          } label: {
            Text(tiling?.name ?? "Select Tiling")
          }
        }
        .frame(maxWidth: 250)

        Spacer()
          .frame(minWidth: 16, maxWidth: 32)

        VStack(alignment: .leading) {
          Text("Hide Other Applications")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)

          ZenCheckbox(isOn: $hideOtherApps) { newValue in
            onHideOtherAppsChange(newValue)
          }
        }

      }
    }
    .padding(8)
    .onAppear {
      onHideOtherAppsChange(hideOtherApps)
      onTilingChange(tiling)
      onSelectedAppsChange(selectedApps)
    }
  }
}

struct WorkspaceApplicationItem {
  let id: UUID
  let application: Application

  init(id: UUID = UUID(), _ application: Application) {
    self.id = id
    self.application = application
  }
}

fileprivate extension WorkspaceCommand.Tiling {
  var name: String {
    switch self {
    case .arrangeLeftRight: "Left & Right"
    case .arrangeRightLeft: "Right & Left"
    case .arrangeTopBottom: "Top & Bottom"
    case .arrangeBottomTop: "Bottom & Top"
    case .arrangeLeftQuarters: "Left & Quarters"
    case .arrangeRightQuarters: "Right & Quarters"
    case .arrangeTopQuarters: "Top & Quarters"
    case .arrangeBottomQuarters: "Bottom & Quarters"
    case .arrangeQuarters: "Quarters"
    case .fill: "Fill"
    case .center: "Center"
    }
  }
}
