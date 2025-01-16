import Apps
import Inject
import Bonzai
import SwiftUI

struct NewCommandTidyView: View {
  @ObserveInjection var inject
  @EnvironmentObject private var applicationStore: ApplicationStore
  @Binding private var validation: NewCommandValidation
  @State private var rules = [TidyApplicationItem]()


  private let onRulesChange: ([TidyApplicationItem]) -> Void

  init(validation: Binding<NewCommandValidation>, onRulesChange: @escaping ([TidyApplicationItem]) -> Void) {
    _validation = validation
    self.onRulesChange = onRulesChange
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
              rules.append(TidyApplicationItem(id: UUID(), application, tiling: .left))
              onRulesChange(rules)
            }, label: { Text(application.displayName) })
          }
        } label: {
          Text("Add Application")
        }
        .menuStyle(.regular)
        .padding(4)

        CompatList {
          ForEach(Array(zip(rules.indices, rules)), id: \.0) { offset, item in
            VStack(spacing: 0) {
              HStack {
                IconView(icon: Icon.init(item.application), size: CGSize(width: 18, height: 18))
                Text(item.application.displayName)
                  .frame(maxWidth: .infinity, alignment: .leading)

                TidyWindowTilingMenu(offset: offset, rules: $rules) {
                  onRulesChange(rules)
                }

                Button {
                  if offset <= rules.count - 1 {
                    let selectedApp = rules[offset]
                    if item.application == selectedApp.application {
                      rules.remove(at: offset)
                      onRulesChange(rules)
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
            rules.move(fromOffsets: indexSet, toOffset: offset)
            onRulesChange(rules)
          }
        }
        .overlay(NewCommandValidationView($validation).zIndex(100))
      }
      .roundedContainer(padding: 0, margin: 0)
      .padding([.leading, .trailing], 4)
      .padding(.bottom, 8)
    }
    .padding(8)
    .onAppear {
      onRulesChange(rules)
      validation = .valid
    }
    .enableInjection()
  }
}

fileprivate struct TidyWindowTilingMenu: View {
  private static let validWindowTiling: [WindowTiling] = [
    WindowTiling.left,
    WindowTiling.right,
    WindowTiling.top,
    WindowTiling.bottom,
    WindowTiling.topLeft,
    WindowTiling.topRight,
    WindowTiling.bottomLeft,
    WindowTiling.bottomRight,
    WindowTiling.center,
    WindowTiling.fill,
  ]

  @Binding var rules: [TidyApplicationItem]
  let offset: Int
  let onChange: () -> Void

  init(offset: Int, rules: Binding<[TidyApplicationItem]>, onChange: @escaping () -> Void) {
    self.offset = offset
    self.onChange = onChange
    _rules = rules
  }

  var body: some View {
    Menu {
      ForEach(Self.validWindowTiling, id: \.identifier) { windowTiling in
        Button(action: {
          rules[offset].tiling = windowTiling
          onChange()
        }, label: { Text(windowTiling.displayValue) })
      }
    } label: {
      if offset < rules.count {
        Text(rules[offset].tiling.displayValue)
      } else {
        Text("Unassigned")
      }
    }
    .menuStyle(.regular)
  }
}

struct TidyApplicationItem {
  let id: UUID
  let application: Application
  var tiling: WindowTiling

  init(id: UUID = UUID(), _ application: Application, tiling: WindowTiling) {
    self.id = id
    self.application = application
    self.tiling = tiling
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
