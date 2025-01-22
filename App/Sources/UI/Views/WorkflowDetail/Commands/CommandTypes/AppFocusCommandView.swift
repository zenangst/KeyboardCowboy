import Apps
import Bonzai
import Inject
import SwiftUI

struct AppFocusCommandView: View {
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObserveInjection var inject
  typealias Model = CommandViewModel.Kind.AppFocusModel
  @State private var model: Model

  private let onTilingChange: (WorkspaceCommand.Tiling?) -> Void
  private let onSelectedAppsChange: (Application) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void
  private let onCreateWindowChange: (Bool) -> Void

  init(model: Model,
       onTilingChange: @escaping (WorkspaceCommand.Tiling?) -> Void,
       onSelectedAppsChange: @escaping (Application) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void,
       onCreateWindowChange: @escaping (Bool) -> Void
  ) {
    self.model = model
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
    self.onCreateWindowChange = onCreateWindowChange
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Applications")
          .font(.subheadline)
        Menu {
          Button(action: {
            let application = Application.currentApplication()
            model.application = application
            onSelectedAppsChange(application)
          }, label: { Text("Current Application") })
          ForEach(applicationStore.applications) { application in
            Button(action: {
              model.application = application
              onSelectedAppsChange(application)
            },
                   label: {
              Text(application.displayName)
            })
          }
        } label: {
          Group {
            if model.application?.bundleIdentifier == Application.currentAppBundleIdentifier() {
              Text("Current Application")
            } else if let application = model.application {
              IconView(icon: Icon(application), size: .init(width: 24, height: 24))
              Text(application.displayName)
            } else {
              Text("Add Application")
            }
          }
            .font(.caption)
        }
        .menuStyle(.regular)
      }
      .padding(.horizontal, 4)

      VStack(alignment: .leading, spacing: 8) {
        Text("Window Tiling")
          .font(.subheadline)

        Grid {
          GridRow {
            switch model.tiling {
            case .arrangeLeftRight:
              WindowTilingIcon(kind: .arrangeLeftRight, size: 20)
            case .arrangeRightLeft:
              WindowTilingIcon(kind: .arrangeRightLeft, size: 20)
            case .arrangeTopBottom:
              WindowTilingIcon(kind: .arrangeTopBottom, size: 20)
            case .arrangeBottomTop:
              WindowTilingIcon(kind: .arrangeBottomTop, size: 20)
            case .arrangeLeftQuarters:
              WindowTilingIcon(kind: .arrangeLeftQuarters, size: 20)
            case .arrangeRightQuarters:
              WindowTilingIcon(kind: .arrangeRightQuarters, size: 20)
            case .arrangeTopQuarters:
              WindowTilingIcon(kind: .arrangeTopQuarters, size: 20)
            case .arrangeBottomQuarters:
              WindowTilingIcon(kind: .arrangeBottomQuarters, size: 20)
            case .arrangeDynamicQuarters:
              WindowTilingIcon(kind: .arrangeDynamicQuarters, size: 20)
            case .arrangeQuarters:
              WindowTilingIcon(kind: .arrangeQuarters, size: 20)
            case .fill:
              WindowTilingIcon(kind: .fill, size: 20)
            case .center:
              WindowTilingIcon(kind: .center, size: 20)
            case .none:
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 20)
            }

            Menu {
              Button {
                model.tiling = nil
                onTilingChange(nil)
              } label: {
                Text("No Tiling")
              }
              ForEach(WorkspaceCommand.Tiling.allCases) { tiling in
                Button {
                  model.tiling = tiling
                  onTilingChange(tiling)
                } label: {
                  Text(tiling.name)
                }
              }
            } label: {
              Text(model.tiling?.name ?? "No Tiling")
                .font(.caption)
            }
            .menuStyle(.zen(.init(grayscaleEffect: .constant(true), hoverEffect: .constant(true))))
            .frame(minHeight: 20)
          }

          GridRow {
            HideAllIconView(size: 20)
            HStack {
              Text("Hide Other Applications")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
              ZenCheckbox(isOn: $model.hideOtherApps) { newValue in
                onHideOtherAppsChange(newValue)
              }
            }
          }

          GridRow {
            WindowManagementIconView(size: 20)
            HStack {
              Text("Create New Window")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
              ZenCheckbox(isOn: $model.createNewWindow) { newValue in
                onCreateWindowChange(newValue)
              }
            }
          }
        }
      }
      .padding(4)
    }
    .enableInjection()
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
