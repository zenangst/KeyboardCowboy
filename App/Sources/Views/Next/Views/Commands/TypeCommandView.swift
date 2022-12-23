import SwiftUI

struct TypeCommandView: View {
  enum Action {
    case save
    case commandAction(CommandContainerAction)
  }
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel
  @State var source: String
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _source = .init(initialValue: "")
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      isEnabled: $command.isEnabled,
      icon: {
        Rectangle()
          .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        RegularKeyIcon(letter: "(...)", width: 24, height: 24)
          .frame(width: 16, height: 16)
      }, content: {
        ZStack(alignment: .leading) {
          TextEditor(text: $source)
            .font(.body)
            .padding(.top, 8)
            .scrollIndicators(.hidden)
          Text("Enter text...")
            .opacity(source.isEmpty ? 0.5 : 0)
            .allowsHitTesting(false)
            .padding(.leading, 4)
        }
      }, subContent: {
        EmptyView()
      }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct TypeCommandView_Previews: PreviewProvider {
  static var previews: some View {
    TypeCommandView(.constant(DesignTime.typeCommand), onAction: { _ in })
  }
}