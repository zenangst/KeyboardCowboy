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
  private let command: DetailViewModel.CommandViewModel
  private let icon: () -> IconContent
  private let content: () -> Content
  private let subContent: () -> SubContent
  private let onAction: (CommandContainerAction) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       @ViewBuilder icon: @escaping () -> IconContent,
       @ViewBuilder content: @escaping () -> Content,
       @ViewBuilder subContent: @escaping () -> SubContent,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _isEnabled = .init(initialValue: command.isEnabled)
    self.command = command
    self.icon = icon
    self.content = content
    self.subContent = subContent
    self.onAction = onAction
  }

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          icon()
            .frame(maxWidth: 32, maxHeight: 32)
          .offset(x: 2)

          content()
            .frame(minHeight: 30)
        }
        .padding([.top, .leading], 8)

        HStack(spacing: 0) {
          Toggle("", isOn: $isEnabled)
            .onChange(of: isEnabled, perform: {
              onAction(.toggleIsEnabled($0))
            })
            .toggleStyle(.switch)
            .tint(.green)
            .scaleEffect(0.65)

          subContent()
            .buttonStyle(.appStyle)
            .padding(.leading, 2)
        }
        .padding([.bottom], 8)
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
