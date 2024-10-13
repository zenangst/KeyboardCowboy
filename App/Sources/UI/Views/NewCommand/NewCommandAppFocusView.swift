import Apps
import Bonzai
import Inject
import SwiftUI

struct NewCommandAppFocusView: View {
  @ObserveInjection var inject
  typealias Tiling = WorkspaceCommand.Tiling
  @EnvironmentObject private var applicationStore: ApplicationStore
  @State private var tiling: Tiling?
  @State private var selectedApp: AppFocusApplicationItem?
  @State private var hideOtherApps = false
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
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading) {
        Text("Applications")
          .font(.subheadline)

        Menu {
          ForEach(applicationStore.applications) { application in
            Button(action: {
              selectedApp = AppFocusApplicationItem(application)
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
      }
      .padding(4)

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
      .padding(4)

      VStack(alignment: .leading) {
        Text("Settings")
          .font(.subheadline)

        HStack {
          ZenCheckbox(isOn: $hideOtherApps) { newValue in
            onHideOtherAppsChange(newValue)
          }
          Text("Hide Other Apps")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)

        HStack {
          ZenCheckbox(isOn: $createNewWindow) { newValue in
            onCreateNewWindowChange(newValue)
          }
          Text("Create New Window")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
      }
      .padding(4)
    }
    .padding(8)
    .onAppear {
      onHideOtherAppsChange(hideOtherApps)
      onTilingChange(tiling)
    }
    .enableInjection()
  }
}

struct AppFocusApplicationItem {
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

