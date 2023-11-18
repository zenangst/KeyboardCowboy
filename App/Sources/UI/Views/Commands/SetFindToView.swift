import Bonzai
import SwiftUI

struct SetFindToView: View {
  enum Action {
    case updateInput(newInput: String)
    case commandAction(CommandContainerAction)
  }

  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.SetFindToModel
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.SetFindToModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
  }


  var body: some View {
    CommandContainerView(
      $metaData,
      icon: {
        metaData in
        ZStack {
          Rectangle()
            .fill(Color(.controlAccentColor).opacity(0.375))
            .cornerRadius(8, antialiased: false)
          RegularKeyIcon(letter: "(...)", width: 24, height: 24)
            .frame(width: 16, height: 16)
        }
      },
      content: { metaData in
        TextField("Value", text: $model.text)
          .onChange(of: model.text, perform: { value in
            onAction(.updateInput(newInput: value))
          })
          .textFieldStyle(.regular(nil))
      },
      subContent: { _ in },
      onAction: { onAction(.commandAction($0)) })
  }
}

#Preview {
  SetFindToView(.init(name: "Test", namePlaceholder: ""), model: .init(id: UUID().uuidString, text: "func"), onAction: { _ in })
}
