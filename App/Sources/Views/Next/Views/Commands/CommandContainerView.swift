import SwiftUI

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @ObserveInjection var inject
  @Binding var isEnabled: Bool
  @ViewBuilder var icon: () -> IconContent
  @ViewBuilder var content: () -> Content
  @ViewBuilder var subContent: () -> SubContent
  var onAction: () -> Void

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .center, spacing: 10) {
        ZStack {
          icon()
            .aspectRatio(contentMode: .fit)
            .frame(width: 42)
        }

        Toggle("", isOn: $isEnabled)
          .tint(.green)
          .toggleStyle(.switch)
          .offset(x: -4)
      }
      .padding([.top, .leading, .bottom], 10)

      VStack(alignment: .leading, spacing: 12) {
        content()
          .frame(minHeight: 30)
          .padding(.bottom, 8)
        subContent()
          .buttonStyle(KCButtonStyle())
      }
      .padding(4)


      HStack {
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

        VStack(spacing: 4) {
          Button(action: onAction,
                 label: {
            Image(systemName: "xmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 8)
          })
          .buttonStyle(.plain)
          .frame(width: 32, height: 32)

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
          .frame(width: 32)


          Button(action: {},
                 label: {
            Image(systemName: "play.fill")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 8)
              .offset(x: 0.5)
              .padding(6)
              .compositingGroup()
          })
          .buttonStyle(.plain)
          .frame(width: 32, height: 32)
        }
        .padding(.trailing, 8)
      }
      .background(gradient)
    }
    .enableInjection()
  }

  var gradient: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(
          stops: [
            .init(color: Color(.windowBackgroundColor).opacity(0.35), location: 0.25),
            .init(color: Color(.textBackgroundColor), location: 1.0),
          ]),
        startPoint: .top,
        endPoint: .bottom)
      .shadow(radius: 2)
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
      subContent: { Text("Baz") }) {}
  }
}
