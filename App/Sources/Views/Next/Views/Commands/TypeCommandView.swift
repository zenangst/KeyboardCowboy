import SwiftUI

struct TypeCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateSource(newInput: String)
    case commandAction(CommandContainerAction)
  }
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel
  @State private var source: String
  @State private var name: String
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.wrappedValue.name)

    switch command.kind.wrappedValue {
    case .type(let input):
      _source = .init(initialValue: input)
    default:
      _source = .init(initialValue: "")
    }

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
        TypeCommandTextEditor(text: $source)
          .onChange(of: source) { newInput in
            onAction(.updateSource(newInput: newInput))
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

struct TypeCommandTextEditor: View {
  @ObserveInjection var inject
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false
  @Binding var text: String

  init(text: Binding<String>) {
    _text = text
  }

  var body: some View {
    ZStack(alignment: .leading) {
      TextEditor(text: $text)
        .scrollContentBackground(.hidden)
        .font(.body)
        .padding(.top, 4)
        .scrollIndicators(.hidden)
      Text("Enter text...")
        .animation(nil, value: text.isEmpty)
        .opacity(text.isEmpty ? 0.5 : 0)
        .animation(.default, value: text.isEmpty)
        .allowsHitTesting(false)
        .padding(.leading, 4)
    }
    .padding(4)
    .background(
      ZStack {
      RoundedRectangle(cornerRadius: 4)
        .fill(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor))
        .opacity(isFocused ? 0.15 : isHovered ? 0.015 : 0)

      RoundedRectangle(cornerRadius: 4)
        .stroke(Color(isFocused ? .controlAccentColor.withAlphaComponent(0.5) : .windowFrameTextColor), lineWidth: 1)
        .opacity(isFocused ? 0.75 : isHovered ? 0.15 : 0)
      }
    )
    .onHover(perform: { newValue in  withAnimation { isHovered = newValue } })
    .focusable()
    .focused($isFocused)
    .enableInjection()
  }
}
