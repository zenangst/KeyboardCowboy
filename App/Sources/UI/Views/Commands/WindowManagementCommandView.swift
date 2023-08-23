import SwiftUI

struct WindowManagementCommandView: View {
  enum Action {
    case onUpdate(CommandViewModel.Kind.WindowManagementModel)
    case commandAction(CommandContainerAction)
  }

  @Binding var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.WindowManagementModel

  private let onAction: (Action) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       model: CommandViewModel.Kind.WindowManagementModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = metaData
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, icon: { command in
      ZStack {
        RoundedRectangle(cornerSize: .init(width: 8, height: 8))
          .stroke(Color.white.opacity(0.4), lineWidth: 2.0)
          .frame(width: 32, height: 32, alignment: .center)
          .background {
            RoundedRectangle(cornerSize: .init(width: 8, height: 8))
              .fill(Color(.controlAccentColor).opacity(0.375))
              .cornerRadius(8, antialiased: false)
          }
          .overlay(alignment: .center) {
            RoundedRectangle(cornerSize: .init(width: 4, height: 4))
              .frame(width: 10, height: 10)
          }
      }
    }, content: { _ in
      Menu(content: {
        ForEach(WindowCommand.Kind.allCases) { kind in
          Button(kind.displayValue) {
            model.kind = kind
            onAction(.onUpdate(model))
          }
        }
      }, label: {
        Text(model.kind.displayValue)
      })
      .menuStyle(GradientMenuStyle(.init(nsColor: .gray), fixedSize: false))
    }, subContent: { _ in }) {
      onAction(.commandAction($0))
    }
  }
}

struct WindowManagementCommandView_Previews: PreviewProvider {
  static let command = DesignTime.windowCommand
  static var previews: some View {
    WindowManagementCommandView(
      .constant(command.model.meta),
      model: command.kind
    ) { _ in }
      .designTime()
  }
}
