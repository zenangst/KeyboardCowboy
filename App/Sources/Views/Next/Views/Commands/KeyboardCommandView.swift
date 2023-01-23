import SwiftUI

struct KeyboardCommandView: View {
  enum Action {
    case updateName(newName: String)
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @Binding private var command: DetailViewModel.CommandViewModel
  @State private var name: String
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>, onAction: @escaping (Action) -> Void) {
    _command = command
    _name = .init(initialValue: command.wrappedValue.name)
    self.onAction = onAction
  }

  var body: some View {
    Group {
      if case .keyboard = command.kind {
        CommandContainerView(
          $command, icon: {
            ZStack {
              Rectangle()
                .fill(Color(nsColor: .systemGreen))
                .opacity(0.2)
                .cornerRadius(8)
              ZStack {
                RegularKeyIcon(letter: "")
                Image(systemName: "flowchart")
              }
              .scaleEffect(0.8)
            }
          }, content: {
            HStack {
              TextField("", text: $name)
                .textFieldStyle(AppTextFieldStyle())
                .onChange(of: name, perform: {
                  onAction(.updateName(newName: $0))
                })
              Spacer()
            }
          },
          subContent: {
            HStack {
              Text("Sequence:")
                .font(.footnote)
              ScrollView(.horizontal) {
                if case .keyboard(var keys) = command.kind {
                  EditableStack(.constant(keys),
                                axes: .horizontal, lazy: false, onMove: { from, to in
                    withAnimation {
                      keys.move(fromOffsets: from, toOffset: to)
                    }
                  }, onDelete: { _ in

                  }) { key in
                    HStack {
                      ForEach(key.wrappedValue.modifiers) { modifier in
                        ModifierKeyIcon(key: modifier)
                          .frame(minWidth: modifier == .command ? 24 : 16, minHeight: 16)
                      }
                      RegularKeyIcon(letter: key.wrappedValue.displayValue, width: 24, height: 24)
                        .fixedSize(horizontal: true, vertical: true)
                    }
                  }
                  .padding(4)
                }
              }
              Spacer()
              Button(action: {},
                     label: { Image(systemName: "plus").frame(width: 10, height: 10) })
                .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.25))
            .cornerRadius(4)
          },
          onAction: { onAction(.commandAction($0)) })
      } else {
        Text("Wrong kind")
      }
    }
    .enableInjection()
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  static var previews: some View {
    KeyboardCommandView(.constant(DesignTime.rebindingCommand), onAction: { _ in })
      .frame(maxHeight: 80)
  }
}
