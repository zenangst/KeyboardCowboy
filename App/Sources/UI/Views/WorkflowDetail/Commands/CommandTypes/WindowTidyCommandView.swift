import Apps
import Bonzai
import Inject
import SwiftUI

struct WindowTidyCommandView: View {
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObserveInjection var inject
  @State private var model: CommandViewModel.Kind.WindowTidyModel

  private let onRulesChange: ([CommandViewModel.Kind.WindowTidyModel.Rule]) -> Void

  init(_ model: CommandViewModel.Kind.WindowTidyModel,
       onRulesChange: @escaping ([CommandViewModel.Kind.WindowTidyModel.Rule]) -> Void)
  {
    self.model = model
    self.onRulesChange = onRulesChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Menu {
        ForEach(applicationStore.applications) { application in
          Button(action: {
            if !model.rules.contains(where: { $0.application == application }) {
              model.rules.append(.init(application: application, tiling: .left))
              onRulesChange(model.rules)
            }
          }, label: { Text(application.displayName) })
        }
      } label: {
        Text("Add Application")
      }
      .style(.derived)

      ZenDivider()

      CompatList {
        ForEach(Array(zip(model.rules.indices, model.rules)), id: \.0) { offset, item in
          HStack {
            IconView(icon: Icon(item.application), size: CGSize(width: 18, height: 18))

            Text(item.application.displayName)
              .font(.caption)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)

            TidyWindowTilingMenu(offset: offset, rules: $model.rules) {
              onRulesChange(model.rules)
            }
            .frame(idealWidth: 100)
            .fixedSize()

            Button {
              if offset <= model.rules.count - 1 {
                let selectedApp = model.rules[offset]
                if item.application == selectedApp.application {
                  model.rules.remove(at: offset)
                  onRulesChange(model.rules)
                }
              }
            } label: {
              Image(systemName: "xmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 8, height: 10)
            }
            .buttonStyle(.destructive)
          }
          .frame(minHeight: 34)
          .background(alignment: .bottom) {
            ZenDivider()
          }
        }
        .onMove { indexSet, offset in
          model.rules.move(fromOffsets: indexSet, toOffset: offset)
          onRulesChange(model.rules)
        }
      }
      .frame(minHeight: max(48, min(CGFloat(model.rules.count) * 32, 304)))
    }
    .enableInjection()
  }
}

private struct TidyWindowTilingMenu: View {
  @ObserveInjection var inject
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

  @Binding var rules: [CommandViewModel.Kind.WindowTidyModel.Rule]
  let offset: Int
  let onChange: () -> Void

  init(offset: Int, rules: Binding<[CommandViewModel.Kind.WindowTidyModel.Rule]>, onChange: @escaping () -> Void) {
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
          .font(.caption)
      } else {
        Text("Unassigned")
          .font(.caption)
      }
    }
    .enableInjection()
  }
}
