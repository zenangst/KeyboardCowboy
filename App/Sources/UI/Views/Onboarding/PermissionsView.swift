import Inject
import SwiftUI
import Bonzai

struct PermissionsView: View {
  @ObserveInjection var inject
  enum Action {
    case github
    case requestPermissions
  }
  @State var animated: Bool = false
  @State var done: Bool = false

  var onAction: (Action) -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 16) {
        Image(.applicationIcon)
          .resizable()
          .frame(width: 84, height: 84)
        Text("Accessibility Permissions are required for Keyboard Cowboy application to function properly.")
          .font(.title2)
      }
      .padding([.leading, .top, .trailing], 16)

      ZenDivider()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Group {
            Text("This allows our application to record hotkeys and perform other actions.")
            Text("Rest assured that we do not use this information for any purpose other than to serve you.")
          }
          .font(.headline)
          Text("Keyboard Cowboy comes with built-in security measures to protect your sensitive information. Password fields and other secure inputs cannot be monitored by our application.")
          Text("Keyboard Cowboy is designed to be secure and private.")
            .font(.headline)
          Text("It does not collect any personal information or send any data to third parties. All data is stored locally on your computer and is never transmitted over the internet.")
          Text("Additionally, Keyboard Cowboy is 100% open source, so you can review the code for yourself.")

          Text("tl;dr")
            .bold()

          Text("We don't stalk you, we don't collect your data, we don't sell your data. We don't even know who you are. But we care about your privacy and security. ❤️")

          Text("If you have any concerns, please contact us.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .roundedSubStyle(padding: 16)
      .style(.derived)

      ZenDivider()

      HStack {
        Button("View source code", action: {
          onAction(.github)
        })
        .environment(\.buttonBackgroundColor, .systemPurple)
        .environment(\.buttonPadding, .large)
        Spacer()

        Button("Request permission", action: {
          done.toggle()
          onAction(.requestPermissions)
        })
        .buttonStyle(.positive)
        .environment(\.buttonBackgroundColor, .systemGreen)
        .environment(\.buttonHoverEffect, false)
        .environment(\.buttonFocusEffect, false)
        .environment(\.buttonGrayscaleEffect, false)
        .environment(\.buttonPadding, .large)
      }
      .roundedStyle()
      .style(.derived)

      Spacer()
    }
    .compositingGroup()
    .style(.section(.detail))
    .frame(minHeight: 560, maxHeight: .infinity, alignment: .top)
    .background(SplashView(done: $done))
    .onAppear {
      animated = true
    }
    .enableInjection()
  }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
      PermissionsView(onAction: { _ in })
        .previewLayout(.sizeThatFits)
    }
}
