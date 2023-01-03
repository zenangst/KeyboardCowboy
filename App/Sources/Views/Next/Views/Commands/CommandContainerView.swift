import SwiftUI

enum CommandContainerAction {
  case run
  case delete
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @ObserveInjection var inject
  @Binding var isEnabled: Bool
  @ViewBuilder var icon: () -> IconContent
  @ViewBuilder var content: () -> Content
  @ViewBuilder var subContent: () -> SubContent
  var onAction: (CommandContainerAction) -> Void

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          ZStack {
            icon()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: 32, maxHeight: 32)
          }

          content()
            .frame(minHeight: 30)
        }
        .padding([.top, .leading], 8)

        HStack(spacing: 0) {
          Toggle("", isOn: $isEnabled)
            .tint(.green)
            .toggleStyle(.switch)
            .scaleEffect(0.65)
            .offset(x: -2)

          subContent()
            .buttonStyle(.appStyle)
            .padding(.leading, 2)
        }
        .padding([.bottom], 8)
      }
      Spacer()
      actionButtons
    }
    .enableInjection()
  }

  var actionButtons: some View {
    HStack(spacing: 0) {
      HStack(spacing: 0) {
        Rectangle()
          .fill(Color(nsColor: .gray))
          .frame(width: 1)
          .opacity(0.15)
        Rectangle()
          .fill(Color(nsColor: .black))
          .frame(width: 1)
          .opacity(0.5)
      }

      VStack(spacing: 0) {
        Spacer()
        Button(action: { onAction(.delete) },
               label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .frame(width: 10, height: 10)
        Spacer()
        VStack(spacing: 0) {
          Rectangle()
            .fill(Color(nsColor: .gray))
            .frame(height: 1)
            .opacity(0.15)
          Rectangle()
            .fill(Color(nsColor: .black))
            .frame(height: 1)
            .opacity(0.5)
        }
        Spacer()
        Button(action: { onAction(.run) },
               label: {
          Image(systemName: "play")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .frame(width: 10, height: 10)
        Spacer()
      }
      .buttonStyle(.plain)
      .frame(width: 32)
      .offset(x: -1, y: 1)
    }
  }
}

struct CommandContainerView_Previews: PreviewProvider {
  static var previews: some View {
    CommandContainerView(
      isEnabled: .constant(true),
      icon: { Text("Foo") },
      content: {
        Text("Bar")
      },
      subContent: { Text("Baz") }) { _ in }
      .frame(maxHeight: 80)
  }
}
