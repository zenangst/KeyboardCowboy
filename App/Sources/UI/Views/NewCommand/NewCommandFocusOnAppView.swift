import Apps
import Bonzai
import SwiftUI

struct NewCommandFocusOnAppView: View {
  typealias Tiling = WorkspaceCommand.Tiling
  @EnvironmentObject private var applicationStore: ApplicationStore
  @State private var tiling: Tiling?
  @State private var selectedApp: FocusOnAppApplicationItem?
  @State private var hideOtherApps = true
  @State private var createNewWindow = false

  private let onTilingChange: (Tiling?) -> Void
  private let onSelectedAppsChange: (String) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void
  private let onCreateNewWindowChange: (Bool) -> Void

  init(onTilingChange: @escaping (Tiling?) -> Void,
       onSelectedAppsChange: @escaping (String) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void,
       onCreateNewWindowChange: @escaping (Bool) -> Void
  ) {
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
    self.onCreateNewWindowChange = onCreateNewWindowChange
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Applications")
        .font(.subheadline)
      VStack(spacing: 0) {
        Menu {
          ForEach(applicationStore.applications) { application in
            Button(action: {
              selectedApp = FocusOnAppApplicationItem(application)
              onSelectedAppsChange(application.bundleIdentifier)
            },
                   label: { Text(application.displayName) })
          }
        } label: {
          if let selectedApp {
            Text(selectedApp.application.displayName)
          } else {
            Text("Select Application")
          }
        }
        .menuStyle(.regular)
        .padding(4)

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

          VStack(alignment: .leading) {
            Text("Create New Window")
              .font(.subheadline)
              .frame(maxWidth: .infinity, alignment: .leading)

            ZenCheckbox(isOn: $createNewWindow) { newValue in
              onCreateNewWindowChange(newValue)
            }
          }
        }
      }
    }
    .padding(8)
    .onAppear {
      onHideOtherAppsChange(hideOtherApps)
      onTilingChange(tiling)
    }
  }
}

struct FocusOnAppApplicationItem {
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

