import SwiftUI

struct TypeCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateSource(newInput: String)
    case commandAction(CommandContainerAction)
  }
  @State var command: DetailViewModel.CommandViewModel
  @State private var source: String
  @State private var name: String
  @State private var notify: Bool
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    _notify = .init(initialValue: command.notify)

    switch command.kind {
    case .type(let input):
      _source = .init(initialValue: input)
      debounce = DebounceManager(for: .milliseconds(500)) { newInput in
        onAction(.updateSource(newInput: newInput))
      }
    default:
      _source = .init(initialValue: "")
      debounce = DebounceManager(for: .milliseconds(500)) { _ in }
    }

    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $command,
      icon: { command in
        ZStack {
          Rectangle()
            .fill(Color(.controlAccentColor).opacity(0.375))
            .cornerRadius(8, antialiased: false)
          RegularKeyIcon(letter: "(...)", width: 24, height: 24)
            .frame(width: 16, height: 16)
        }
      }, content: { command in
        TypeCommandTextEditor(text: $source)
          .onChange(of: source) { debounce.send($0) }
      }, subContent: { _ in }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

struct TypeCommandView_Previews: PreviewProvider {
  static var previews: some View {
    TypeCommandView(DesignTime.typeCommand, onAction: { _ in })
      .frame(idealHeight: 120, maxHeight: 180)
  }
}

struct TypeCommandTextEditor: View {
  @FocusState var isFocused: Bool
  @State var isHovered: Bool = false
  @Binding var text: String

  private var onCommandReturnKey: (() -> Void)?

  init(text: Binding<String>, onCommandReturnKey: (() -> Void)? = nil) {
    _text = text
    self.onCommandReturnKey = onCommandReturnKey
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      TextEditor(text: $text)
        .scrollContentBackground(.hidden)
        .font(.body)
        .padding(.top, 4)
        .scrollIndicators(.hidden)
      Text("Enter text...")
        .animation(nil, value: text.isEmpty)
        .opacity(text.isEmpty ? 0.5 : 0)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .allowsHitTesting(false)
        .padding([.leading, .top], 4)
      Button("", action: { onCommandReturnKey?() })
        .opacity(0.0)
        .keyboardShortcut(.return, modifiers: [.command])
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
    .onHover(perform: { newValue in  withAnimation(.easeInOut(duration: 0.2)) { isHovered = newValue } })
    .focusable()
    .focused($isFocused)
  }
}
