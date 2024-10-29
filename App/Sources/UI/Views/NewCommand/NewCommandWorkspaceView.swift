import Apps
import Inject
import Bonzai
import SwiftUI

struct NewCommandWorkspaceView: View {
  @ObserveInjection var inject
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
    VStack(alignment: .leading, spacing: 0) {
      Text("Applications")
        .font(.subheadline)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)

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

        CompatList {
          ForEach(Array(zip(selectedApps.indices, selectedApps)), id: \.0) { offset, item in
            VStack(spacing: 0) {
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
              .padding(4)
              ZenDivider()
            }
          }
          .onMove { indexSet, offset in
            selectedApps.move(fromOffsets: indexSet, toOffset: offset)
            onSelectedAppsChange(selectedApps)
          }
        }
      }
      .roundedContainer(padding: 0, margin: 0)
      .padding([.leading, .trailing], 4)
      .padding(.bottom, 8)

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
      .padding(4)

      VStack(alignment: .leading) {
        Text("Settings")
          .font(.subheadline)
        HStack {
          ZenCheckbox(isOn: $hideOtherApps) { newValue in
            onHideOtherAppsChange(newValue)
          }
          Text("Hide Other Applications")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(4)
    }
    .padding(8)
    .onAppear {
      onHideOtherAppsChange(hideOtherApps)
      onTilingChange(tiling)
      onSelectedAppsChange(selectedApps)
    }
    .enableInjection()
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
    case .arrangeDynamicQuarters: "Dynamic & Quarters"
    case .arrangeQuarters: "Quarters"
    case .fill: "Fill"
    case .center: "Center"
    }
  }
}
