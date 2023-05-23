import SwiftUI

struct EmptyConfigurationView: View {
  enum Action {
    case empty
    case initial
  }

  @State var done: Bool = false
  private let colors = SplashColors(primaryColor: Color(.systemGreen),
                                    secondaryColor: Color(.systemBlue),
                                    backgroundColor: Color(.sRGB, red: 0.03, green: 0.11, blue: 0.25, opacity: 1.0))
  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        KeyboardCowboyAsset.applicationIcon.swiftUIImage
          .resizable()
          .frame(width: 64, height: 64)
        Text("Welcome to Keyboard Cowboy!")
          .font(.title)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Text("To get started, you can either select an empty configuration or choose from our prefilled configurations with default groups.\n\nSimply tap on the option you prefer and you'll be ready to go!")
        .font(.title3)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()
      Divider()

      HStack {
        VStack {
          Button("Empty Configuration", action: {
            onAction(.empty)
          })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGray, hoverEffect: false)))
          Text(" ")
            .font(.footnote)
        }

        VStack {
          Button("Start Configuration", action: {
            onAction(.initial)
          })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
          Text("Recommended")
            .font(.footnote)
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(SplashView(colors: colors, done: $done))
  }
}

struct EmptyConfigurationView_Previews: PreviewProvider {
  static var previews: some View {
    EmptyConfigurationView { _ in }
  }
}
