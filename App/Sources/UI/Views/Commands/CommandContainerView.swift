import SwiftUI

enum CommandContainerAction {
  case run
  case delete
  case changeDelay(Double?)
  case toggleIsEnabled(Bool)
  case toggleNotify(Bool)
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @State private var isEnabled: Bool
  @State private var notify: Bool
  @State private var delay: Double?
  @State private var delayString: String = ""
  @State private var delayOverlay: Bool = false

  @EnvironmentObject var detailPublisher: DetailPublisher
  @Binding private var command: DetailViewModel.CommandViewModel
  private let icon: (Binding<DetailViewModel.CommandViewModel>) -> IconContent
  private let content: (Binding<DetailViewModel.CommandViewModel>) -> Content
  private let subContent: (Binding<DetailViewModel.CommandViewModel>) -> SubContent
  private let onAction: (CommandContainerAction) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       @ViewBuilder icon: @escaping (Binding<DetailViewModel.CommandViewModel>) -> IconContent,
       @ViewBuilder content: @escaping (Binding<DetailViewModel.CommandViewModel>) -> Content,
       @ViewBuilder subContent: @escaping (Binding<DetailViewModel.CommandViewModel>) -> SubContent,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _isEnabled = .init(initialValue: command.isEnabled.wrappedValue)
    _notify = .init(initialValue: command.notify.wrappedValue)
    _delay = .init(initialValue: command.delay.wrappedValue)
    _command = command
    self.icon = icon
    self.content = content
    self.subContent = subContent
    self.onAction = onAction
  }

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          icon($command)
            .fixedSize()
            .frame(maxWidth: 32, maxHeight: 32)

          content($command)
            .frame(minHeight: 30, maxHeight: .infinity)
        }
        .padding([.top, .leading], 8)

        HStack(spacing: 0) {
          Toggle(isOn: $isEnabled) { }
            .onChange(of: isEnabled, perform: {
              onAction(.toggleIsEnabled($0))
            })
            .toggleStyle(.switch)
            .tint(.green)
            .compositingGroup()
            .scaleEffect(0.65)

          HStack {
            Toggle("Notify", isOn: $notify)
              .onChange(of: notify) { newValue in
                onAction(.toggleNotify(newValue))
              }

            if detailPublisher.data.execution == .serial {
              Button {
                delayOverlay = true
              } label: {
                HStack {
                  if let delay {
                    Text("\(Int(delay)) milliseconds")
                      .font(.caption)
                  } else {
                    Text("No delay")
                      .font(.caption)
                  }
                  Divider()
                    .frame(height: 6)
                  Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 6, height: 6)
                }
              }
              .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGray)))
              .popover(isPresented: $delayOverlay, content: {
                HStack {
                  TextField("Delay", text: $delayString) { isEditing in
                    if !isEditing {
                      if let value = Double(self.delayString) {
                        if value > 0 {
                          self.delay = value
                        } else {
                          self.delay = nil
                        }
                        onAction(.changeDelay(value))
                      }
                    }
                  }
                }
                .padding(16)
              })
            }

            subContent($command)
          }
            .buttonStyle(.appStyle)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.tail)
            .font(.caption)
            .padding(.leading, 8)
        }
        .padding(.bottom, 8)
        .padding(.leading, 4)
      }
      Spacer()
      CommandContainerActionView(onAction: onAction)
    }
  }
}

struct CommandContainerActionView: View {
  let onAction: (CommandContainerAction) -> Void

  var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: 0) {
        Color.gray
          .frame(width: 1)
          .opacity(0.15)
        Color.black
          .frame(width: 1)
          .opacity(0.5)
      }

      VStack(alignment: .center, spacing: 0) {
        Button(action: { onAction(.delete) },
               label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed, grayscaleEffect: true)))
        .frame(width: 20)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 10)

        VStack(spacing: 0) {
          Color.gray
            .frame(height: 1)
            .opacity(0.15)
          Color.black
            .frame(height: 1)
            .opacity(0.5)
        }

        Button(action: { onAction(.run) },
               label: {
          Image(systemName: "play")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
        .frame(width: 20)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 10)
      }
      .buttonStyle(.plain)
      .frame(width: 32)
      .offset(x: -1, y: 1)
    }
  }
}

//struct CommandContainerView_Previews: PreviewProvider {
//  static var previews: some View {
//    CommandContainerView(
//      isEnabled: .constant(true),
//      icon: { Text("Foo") },
//      content: {
//        Text("Bar")
//      },
//      subContent: { Text("Baz") }) { _ in }
//      .frame(maxHeight: 80)
//  }
//}
