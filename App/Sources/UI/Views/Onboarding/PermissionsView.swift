import SwiftUI
import Bonzai

struct PermissionsView: View {
  enum Action {
    case github
    case requestPermissions
  }
  @State var animated: Bool = false
  @State var done: Bool = false

  var onAction: (Action) -> Void

  var body: some View {
    VStack {
      HStack(alignment: .top, spacing: 16) {
        KeyboardCowboyAsset.applicationIcon.swiftUIImage
          .resizable()
          .frame(width: 128, height: 128)
          .opacity(animated ? 1 : 0)
          .animation(.easeInOut(duration: 0.2), value: animated)

        VStack(alignment: .leading, spacing: 16) {
          Text("Accessibility permissions are required for Keyboard Cowboy application to function properly.")
            .font(.title2)
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
            .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                              axis: (x: 1.0, y: 0.0, z: 0.0)
            )
            .animation(.easeInOut(duration: 0.4), value: animated)
          Group {
            Text("This allows our application to record hotkeys and perform other actions.")
              .opacity(animated ? 1 : 0)
              .offset(y: animated ? 0 : -10)
            Text("Rest assured that we do not use this information for any purpose other than to serve you.")
              .opacity(animated ? 1 : 0)
              .offset(y: animated ? 0 : -10)
          }
          .font(.headline)
          Text("Keyboard Cowboy comes with built-in security measures to protect your sensitive information. Password fields and other secure inputs cannot be monitored by our application.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
          Text("Keyboard Cowboy is designed to be secure and private.")
            .font(.headline)
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
          Text("It does not collect any personal information or send any data to third parties. All data is stored locally on your computer and is never transmitted over the internet.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
          Text("Additionally, Keyboard Cowboy is 100% open source, so you can review the code for yourself.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)

          Text("tl;dr")
            .bold()
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)

          Text("We don't stalk you, we don't collect your data, we don't sell your data. We don't even know who you are. But we care about your privacy and security. ❤️")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)

          Text("If you have any concerns, please contact us.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .animation(.easeInOut(duration: 0.8).delay(0.8), value: animated)

      Spacer()

      Divider()
        .opacity(animated ? 1 : 0)
        .animation(.easeInOut(duration: 1.5).delay(1.5), value: animated)
        .padding(.bottom, 4)

      HStack(spacing: 16) {
        Button("View source code", action: {
          onAction(.github)
        })
        .buttonStyle(.calm(color: .systemGreen, padding: .medium))
        Spacer()

        Button("Request permission", action: {
          done.toggle()
          onAction(.requestPermissions)
        })
        .buttonStyle(.positive)
      }
      .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                        axis: (x: 1.0, y: 0.0, z: 0.0)
      )
      .opacity(animated ? 1 : 0)
      .offset(y: animated ? 0 : 60)
      .animation(.default.delay(2), value: animated)
    }
    .compositingGroup()
    .padding()
    .frame(minHeight: 560, maxHeight: .infinity, alignment: .top)
    .background(SplashView(done: $done))
    .onAppear {
      animated = true
    }
  }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
      PermissionsView(onAction: { _ in })
        .previewLayout(.sizeThatFits)
    }
}
