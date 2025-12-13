import Apps
import Bonzai
import HotSwiftUI
import SwiftUI

struct NewCommandWorkspaceView: View {
  @ObserveInjection var inject
  @EnvironmentObject private var applicationStore: ApplicationStore
  @Binding private var validation: NewCommandValidation
  @State private var tiling: WorkspaceCommand.Tiling?
  @State private var selectedApps = [WorkspaceApplicationItem]()
  @State private var hideOtherApps = true

  private let onTilingChange: (WorkspaceCommand.Tiling?) -> Void
  private let onSelectedAppsChange: ([WorkspaceApplicationItem]) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void

  init(validation: Binding<NewCommandValidation>,
       onTilingChange: @escaping (WorkspaceCommand.Tiling?) -> Void,
       onSelectedAppsChange: @escaping ([WorkspaceApplicationItem]) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void)
  {
    _validation = validation
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Applications")
        .font(.subheadline)

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

      CompatList {
        ForEach(Array(zip(selectedApps.indices, selectedApps)), id: \.0) { offset, item in
          VStack(spacing: 8) {
            HStack {
              IconView(icon: Icon(item.application), size: CGSize(width: 18, height: 18))
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
            ZenDivider()
          }
        }
        .onMove { indexSet, offset in
          selectedApps.move(fromOffsets: indexSet, toOffset: offset)
          onSelectedAppsChange(selectedApps)
        }
      }
      .overlay(NewCommandValidationView($validation).zIndex(100))
      .roundedStyle(padding: 8)

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

      Text("Settings")
        .font(.subheadline)
      HStack {
        Toggle(isOn: $hideOtherApps, label: { Text("Hide Other Applications") })
          .onChange(of: hideOtherApps) { newValue in
            onHideOtherAppsChange(newValue)
          }
      }
      Spacer()
    }
    .style(.derived)
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

private extension WorkspaceCommand.Tiling {
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
