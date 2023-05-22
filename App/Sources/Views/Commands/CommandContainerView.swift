import SwiftUI

enum CommandContainerAction {
  case run
  case delete
  case toggleIsEnabled(Bool)
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @State var isEnabled: Bool
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
            .frame(minHeight: 30)
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

          subContent($command)
            .buttonStyle(.appStyle)
            .padding(.leading, 2)
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
