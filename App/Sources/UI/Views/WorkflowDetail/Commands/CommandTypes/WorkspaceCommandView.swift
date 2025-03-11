import Apps
import Bonzai
import Inject
import SwiftUI

struct WorkspaceCommandView: View {
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObserveInjection var inject
  @State private var model: CommandViewModel.Kind.WorkspaceModel

  private let onTilingChange: (WorkspaceCommand.Tiling?) -> Void
  private let onSelectedAppsChange: ([Application]) -> Void
  private let onHideOtherAppsChange: (Bool) -> Void

  init(_ model: CommandViewModel.Kind.WorkspaceModel,
       onTilingChange: @escaping (WorkspaceCommand.Tiling?) -> Void,
       onSelectedAppsChange: @escaping ([Application]) -> Void,
       onHideOtherAppsChange: @escaping (Bool) -> Void) {
    self.model = model
    self.onTilingChange = onTilingChange
    self.onSelectedAppsChange = onSelectedAppsChange
    self.onHideOtherAppsChange = onHideOtherAppsChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        ZenLabel("Applications")
          .style(.derived)
        Menu {
          ForEach(applicationStore.applications) { application in
            Button(action: {
              model.applications.append(application)
              onSelectedAppsChange(model.applications)
            },
                   label: { Text(application.displayName) })
          }
        } label: {
          Text("Add Application")
        }
      }

      ZenDivider()

      CompatList {
        ForEach(Array(zip(model.applications.indices, model.applications)), id: \.0) { offset, application in
          HStack(spacing: 8) {
            IconView(icon: Icon(application), size: .init(width: 24, height: 24))
            Text(application.displayName)
              .font(.caption)
            Spacer()
            Button {
              if offset <= model.applications.count - 1 {
                let selectedApp = model.applications[offset]
                if selectedApp == application {
                  model.applications.remove(at: offset)
                  onSelectedAppsChange(model.applications)
                }
              }
            } label: {
              Image(systemName: "xmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 8, height: 10)
            }
          }
          .buttonStyle(.destructive)
          .frame(minHeight: 34)
          .background(alignment: .bottom) {
            ZenDivider()
          }
        }
        .onMove { indexSet, offset in
          model.applications.move(fromOffsets: indexSet, toOffset: offset)
          onSelectedAppsChange(model.applications)
        }
      }
      .frame(minHeight: max(48, min(CGFloat(model.applications.count) * 34, 148)))

      VStack(alignment: .leading, spacing: 2) {
        ZenLabel("Window Tiling")
          .style(.derived)
        ZenDivider()
        Grid {
          GridRow {
            switch model.tiling {
            case .arrangeLeftRight: WindowTilingIcon(kind: .arrangeLeftRight, size: 20)
            case .arrangeRightLeft: WindowTilingIcon(kind: .arrangeRightLeft, size: 20)
            case .arrangeTopBottom: WindowTilingIcon(kind: .arrangeTopBottom, size: 20)
            case .arrangeBottomTop: WindowTilingIcon(kind: .arrangeBottomTop, size: 20)
            case .arrangeLeftQuarters:  WindowTilingIcon(kind: .arrangeLeftQuarters, size: 20)
            case .arrangeDynamicQuarters: WindowTilingIcon(kind: .arrangeLeftQuarters, size: 20)
            case .arrangeRightQuarters: WindowTilingIcon(kind: .arrangeRightQuarters, size: 20)
            case .arrangeTopQuarters: WindowTilingIcon(kind: .arrangeTopQuarters, size: 20)
            case .arrangeBottomQuarters: WindowTilingIcon(kind: .arrangeBottomQuarters, size: 20)
            case .arrangeQuarters: WindowTilingIcon(kind: .arrangeQuarters, size: 20)
            case .fill: WindowTilingIcon(kind: .fill, size: 20)
            case .center: WindowTilingIcon(kind: .center, size: 20)
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
            .frame(minHeight: 20)
          }

          GridRow {
            HideAllIconView(size: 20)
            HStack {
              Text("Hide Other Applications")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
              Toggle(isOn: $model.hideOtherApps, label: {})
                .onChange(of: model.hideOtherApps) { newValue in
                  onHideOtherAppsChange(newValue)
                }
            }
          }
        }
        .style(.derived)
      }
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
