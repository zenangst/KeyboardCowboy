import Bonzai
import HotSwiftUI
import SwiftUI

struct MouseCommandView: View {
  private let iconSize: CGSize
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.MouseModel
  private let xString: String = ""
  private let yString: String = ""

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.MouseModel, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    MouseCommandInternalView(metaData, model: model, iconSize: iconSize)
  }
}

private struct MouseCommandInternalView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  let metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.MouseModel

  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.MouseModel, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { MouseIconView(size: iconSize.width) },
      content: {
        MouseCommandContentView(metaData: metaData, model: $model)
      },
      subContent: {},
    )
  }
}

private struct MouseCommandContentView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  @State private var xString: String = ""
  @State private var yString: String = ""
  let metaData: CommandViewModel.MetaData
  @Binding private var model: CommandViewModel.Kind.MouseModel

  init(metaData: CommandViewModel.MetaData, model: Binding<CommandViewModel.Kind.MouseModel>) {
    self.metaData = metaData
    _model = model

    switch model.wrappedValue.kind {
    case let .click(element):
      switch element.clickLocation {
      case let .custom(x, y):
        _xString = .init(initialValue: String(x))
        _yString = .init(initialValue: String(y))
      default: break
      }
    case let .doubleClick(element):
      switch element.clickLocation {
      case let .custom(x, y):
        _xString = .init(initialValue: String(x))
        _yString = .init(initialValue: String(y))
      default: break
      }
    case let .rightClick(element):
      switch element.clickLocation {
      case let .custom(x, y):
        _xString = .init(initialValue: String(x))
        _yString = .init(initialValue: String(y))
      default: break
      }
    }
  }

  var body: some View {
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
        updater.modifyCommand(withID: metaData.id, using: transaction) { command in
          guard case var .mouse(mouseCommand) = command else { return }

          mouseCommand.kind = newValue
          command = .mouse(mouseCommand)
        }
      })

      if case let .focused(location) = model.kind.element {
        HStack {
          Menu(content: {
            ForEach(MouseCommand.ClickLocation.allCases) { location in
              Button(action: {
                switch model.kind {
                case .click:
                  model.kind = .click(.focused(location))
                case .doubleClick:
                  model.kind = .doubleClick(.focused(location))
                case .rightClick:
                  model.kind = .rightClick(.focused(location))
                }
              }, label: {
                Text(location.displayValue)
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
          }
        }
      }
    }
  }
}

struct MouseCommandView_Previews: PreviewProvider {
  static let command = DesignTime.mouseCommand
  static var previews: some View {
    MouseCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24))
      .designTime()
      .frame(maxHeight: 100)
  }
}
