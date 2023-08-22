import SwiftUI

struct TypeCommandView: View {
  enum Action {
    case updateName(newName: String)
    case updateSource(newInput: String)
    case updateMode(newMode: TypeCommand.Mode)
    case commandAction(CommandContainerAction)
  }
  @Binding var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.TypeModel
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       model: Binding<CommandViewModel.Kind.TypeModel>,
       onAction: @escaping (Action) -> Void) {
    _metaData = metaData
    _model = model
    debounce = DebounceManager(for: .milliseconds(500)) { newInput in
      onAction(.updateSource(newInput: newInput))
    }
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      icon: { metaData in
        ZStack {
          Rectangle()
            .fill(Color(.controlAccentColor).opacity(0.375))
            .cornerRadius(8, antialiased: false)
          RegularKeyIcon(letter: "(...)", width: 24, height: 24)
            .frame(width: 16, height: 16)
        }
      }, content: { metaData in
        TypeCommandTextEditor(text: $model.input)
          .onChange(of: model.input) { debounce.send($0) }
      }, subContent: { _ in
        TypeCommandModeView(mode: $model.mode) { newMode in
          onAction(.updateMode(newMode: newMode))
        }
      }, onAction: { onAction(.commandAction($0)) })
    .debugEdit()
  }
}

fileprivate struct TypeCommandModeView: View {
  @Binding var mode: TypeCommand.Mode
  private let onAction: (TypeCommand.Mode) -> Void

  init(mode: Binding<TypeCommand.Mode>, onAction: @escaping (TypeCommand.Mode) -> Void) {
    _mode = mode
    self.onAction = onAction
  }

  var body: some View {
    Menu(content: {
      ForEach(TypeCommand.Mode.allCases) { mode in
        Button(action: { onAction(mode) }, label: { Text(mode.rawValue) })
      }
    }, label: {
      Text(mode.rawValue)
        .font(.caption)
    })
    .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false)))
  }
}

struct TypeCommandView_Previews: PreviewProvider {
  static let command = DesignTime.typeCommand
  static var previews: some View {
    TypeCommandView(.constant(command.model.meta), 
                    model: .constant(command.kind)) { _ in }
      .designTime()
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
