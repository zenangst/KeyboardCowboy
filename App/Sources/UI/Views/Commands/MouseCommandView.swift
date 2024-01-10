import Bonzai
import Inject
import SwiftUI

struct MouseCommandView: View {
  @ObserveInjection var inject

  enum Action {
    case update(MouseCommand.Kind)
    case commandAction(CommandContainerAction)
  }

  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.MouseModel

  @State private var xString: String = ""
  @State private var yString: String = ""

  private let onAction: (Action) -> Void
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MouseModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      placeholder: model.placeholder,
      icon: { command in
        switch command.icon.wrappedValue {
        case .some(let icon):
          IconView(icon: icon, size: iconSize)
        case .none:
          EmptyView()
        }
      },
      content: { _ in
        HStack {
          Menu(content: {
            ForEach(MouseCommand.Kind.allCases) { kind in
              Button(action: {
                model.kind = kind
              }, label: {
                Text(kind.displayValue)
                  .font(.subheadline)
              })
            }
          }, label: {
            Text(model.kind.displayValue)
              .font(.subheadline)
          })
          .onChange(of: model.kind, perform: { newValue in
            onAction(.update(newValue))
          })

          if case .focused(let location) = model.kind.element {
            HStack {
              Menu(content: {
                ForEach(MouseCommand.ClickLocation.allCases) { clickLocation in
                  Button(action: {
                    switch model.kind {
                    case .click:
                      model.kind = .click(.focused(clickLocation))
                    case .doubleClick:
                      model.kind = .doubleClick(.focused(clickLocation))
                    case .rightClick:
                      model.kind = .rightClick(.focused(clickLocation))
                    }
                  }, label: {
                    Text(clickLocation.displayValue)
                      .font(.subheadline)
                  })
                }
              }, label: {
                Text(location.displayValue)
                  .font(.subheadline)
              })
              .fixedSize()

              if case .custom = location {
                Group {
                  TextField("X", text: $xString)
                    .frame(maxWidth: 50)
                  Text("x")
                  TextField("Y", text: $yString)
                    .frame(maxWidth: 50)
                }
                .textFieldStyle(.regular(nil))
              }
            }
          }
        }
        .menuStyle(.zen(.init(color: .systemGray)))
      },
      subContent: { _ in },
      onAction: { action in
        onAction(.commandAction(action))
      })
      .enableInjection()
  }
}

struct MouseCommandView_Previews: PreviewProvider {
  static let command = DesignTime.mouseCommand
  static var previews: some View {
    MouseCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
      .frame(maxHeight: 100)
  }
}
