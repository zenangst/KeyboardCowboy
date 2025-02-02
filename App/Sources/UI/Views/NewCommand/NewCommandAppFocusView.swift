import Apps
import Bonzai
import Inject
import SwiftUI

struct NewCommandAppFocusView: View {
  @ObserveInjection var inject
  typealias Tiling = WorkspaceCommand.Tiling
  @EnvironmentObject private var applicationStore: ApplicationStore
  @Binding var validation: NewCommandValidation
  @State private var tiling: Tiling?
  @State private var selectedApp: AppFocusApplicationItem?
  @State private var hideOtherApps = false
  @State private var createNewWindow = true

  private let onTilingChange: (Tiling?) -> Void
  private let onSelectedAppsChange: (String) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void
  private let onCreateNewWindowChange: (Bool) -> Void

  init(validation: Binding<NewCommandValidation>,
       onTilingChange: @escaping (Tiling?) -> Void,
       onSelectedAppsChange: @escaping (String) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void,
       onCreateNewWindowChange: @escaping (Bool) -> Void
  ) {
    _validation = validation
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
    self.onCreateNewWindowChange = onCreateNewWindowChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Applications")
        .font(.subheadline)

      Menu {
        Button(action: {
          let application = Application.currentApplication()
          selectedApp = AppFocusApplicationItem(application)
          onSelectedAppsChange(application.bundleIdentifier)
        }, label: { Text("Current Application") })
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
      .overlay(NewCommandValidationView($validation))

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

      VStack(alignment: .leading) {
        Text("Settings")
          .font(.subheadline)

        HStack {
          Toggle(isOn: $hideOtherApps, label: {})
            .onChange(of: hideOtherApps, perform: { newValue in
              onHideOtherAppsChange(newValue)
            })
          Text("Hide Other Apps")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack {
          Toggle(isOn: $createNewWindow, label: {})
            .onChange(of: createNewWindow, perform: { newValue in
              onCreateNewWindowChange(newValue)
            })
          Text("Create New Window")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .style(.derived)
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

