import SwiftUI

struct EmptyConfigurationView: View {
  enum Action {
    case empty
    case initial
  }

  @Namespace var namespace
  @State var done: Bool = false
  @State var selected: Action = .initial
  private let colors = SplashColors(primaryColor: Color(.systemGreen),
                                    secondaryColor: Color(.systemBlue),
                                    backgroundColor: Color(.sRGB, red: 0.03, green: 0.11, blue: 0.25, opacity: 1.0))
  private let onAction: (Action) -> Void
  private let model = KeyboardCowboyConfiguration.default()

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    VStack(spacing: 0) {
      Text("Choose your configuration")
        .font(.title)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(16)

      Divider()

      HStack(spacing: 48) {
        Button(action: {
          selected = .initial
        }, label: {
          LazyVGrid(columns: [
            .init(.adaptive(minimum: 24)),
            .init(.adaptive(minimum: 24)),
            .init(.adaptive(minimum: 24)),
            .init(.adaptive(minimum: 24)),
            .init(.adaptive(minimum: 24)),
          ], spacing: 12) {
            ForEach(model.groups) { group in
              GroupIconView(color: group.color,
                            icon: nil,
                            symbol: group.symbol)
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 2)
            }
          }
        })
        .buttonStyle(EmptyConfigurationButtonStyle(title: "Default",
                                                   subtitle: "Recommended",
                                                   action: .initial,
                                                   selected: $selected))

        Button(action: {
          selected = .empty
        }, label: {
          GroupIconView(color: "#000",
                        icon: nil,
                        symbol: "app.dashed")
            .frame(width: 30, height: 30)
            .shadow(color: .black.opacity(0.3), radius: 1, y: 2)

        })
        .buttonStyle(EmptyConfigurationButtonStyle(title: "Empty",
                                                   subtitle: " ",
                                                   action: .empty,
                                                   selected: $selected))
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .background(.black.opacity(0.5))

      Divider()

      Text("To get started, you can either select an empty configuration or choose from our prefilled configurations with default groups.\n\nSimply tap on the option you prefer and you'll be ready to go!")
        .font(.title3)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal, 32)

      Button(action: {
        onAction(selected)
      }, label: {
        Text("Confirm")
      })
      .padding(.vertical)
      .matchedGeometryEffect(id: "initial-item", in: namespace)
    }
    .roundedStyle(padding: 0)
    .frame(maxWidth: .infinity, minHeight: 480, maxHeight: .infinity, alignment: .leading)
    .background(SplashView(colors: colors, done: $done))
  }
}

struct EmptyConfigurationButtonStyle: ButtonStyle {
  let title: String
  let subtitle: String

  var action: EmptyConfigurationView.Action
  @Binding var selected: EmptyConfigurationView.Action

  func makeBody(configuration: Configuration) -> some View {
    VStack {
      Text(title)
      configuration.label
        .buttonStyle(.plain)
        .frame(width: 188, height: 80)
        .clipped()
        .background(
          EmptyConfigurationBackgroundView(action: action,
                                           selected: $selected),
        )
      Text(subtitle)
        .font(.footnote)
    }
  }
}

struct EmptyConfigurationBackgroundView: View {
  @State var action: EmptyConfigurationView.Action
  @Binding var selected: EmptyConfigurationView.Action

  var body: some View {
    let color: NSColor = action == .initial ? .systemGreen : .systemGray
    let selected = action == selected
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(.systemGreen).opacity(0.5), lineWidth: 6)
        .opacity(selected ? 1 : 0)
      LinearGradient(stops: [
        .init(color: Color(color), location: 0.0),
        .init(color: Color(color.blended(withFraction: 0.3, of: .black)!), location: 0.025),
        .init(color: Color(color.blended(withFraction: 0.5, of: .black)!), location: 1.0),
      ], startPoint: .top, endPoint: .bottom)
        .cornerRadius(8)
    }
    .shadow(
      color: selected
        ? Color(.systemGreen)
        : Color(.sRGBLinear, white: 0, opacity: 0.33),
      radius: 4,
    )
    .animation(.default, value: selected)
  }
}

struct EmptyConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    EmptyConfigurationView { _ in }
      .previewLayout(.sizeThatFits)
  }
}
