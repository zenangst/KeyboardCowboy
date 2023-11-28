import Bonzai
import Inject
import SwiftUI

struct MouseCommandView: View {
  enum Action {
    case update(MouseCommand.Kind)
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.MouseModel

  @State private var xString: String = ""
  @State private var yString: String = ""

  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MouseModel,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      icon: { command in
        switch command.icon.wrappedValue {
        case .some(let icon):
          IconView(icon: icon, size: .init(width: 32, height: 32))
            .overlay(alignment: .bottom) {
              RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .systemYellow))
                .betaFeature("Mouse Commands is currently in beta. If you have any feedback, please reach out to us.") {
                  Text("BETA")
                    .foregroundStyle(Color.black)
                    .font(.caption2)
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 26, height: 12)
                .offset(y: 16)
            }
        case .none:
          EmptyView()
        }
      },
      content: { _ in
        VStack(alignment: .leading) {
          Menu(content: {
            ForEach(MouseCommand.Kind.allCases) { kind in
              Button(action: {
                model.kind = kind
              }, label: {
                Text(kind.displayValue)
              })
            }
          }, label: {
            Text(model.kind.displayValue)
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
                  })
                }
              }, label: {
                Text(location.displayValue)
              })

              if case .custom(let x, let y) = location {
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
        .menuStyle(.regular)
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
    MouseCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .frame(maxHeight: 100)
  }
}
