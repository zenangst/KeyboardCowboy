import SwiftUI

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
      VStack(alignment: .leading, spacing: 16) {
        Text("Accessibility permissions are required for our application to function properly.")
          .font(.title)
          .opacity(animated ? 1 : 0)
          .offset(y: animated ? 0 : -10)
          .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
            axis: (x: 1.0, y: 0.0, z: 0.0)
          )
          .animation(.easeInOut(duration: 0.2), value: animated)

        Group {

          Group {
            Text("This allows our application to record hotkeys and perform other actions.")
              .opacity(animated ? 1 : 0)
              .offset(y: animated ? 0 : -10)
              .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                                axis: (x: 1.0, y: 0.0, z: 0.0)
              )
            Text("Rest assured that we do not use this information for any purpose other than to serve you.")
              .opacity(animated ? 1 : 0)
              .offset(y: animated ? 0 : -10)
              .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                                axis: (x: 1.0, y: 0.0, z: 0.0)
              )
          }
          .font(.headline)
          Text("Keyboard Cowboy comes with built-in security measures to protect your sensitive information. Password fields and other secure inputs cannot be monitored by our application.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
            .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                              axis: (x: 1.0, y: 0.0, z: 0.0)
            )
          Text("We value your privacy and take your security seriously.")
            .font(.headline)
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
            .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                              axis: (x: 1.0, y: 0.0, z: 0.0)
            )
          Text("Additionally, Keyboard Cowboy is 100% open source, so you can review the code for yourself.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
            .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                              axis: (x: 1.0, y: 0.0, z: 0.0)
            )
          Text("If you have any concerns, please contact us.")
            .opacity(animated ? 1 : 0)
            .offset(y: animated ? 0 : -10)
            .rotation3DEffect(Angle(degrees: animated ? 0 : 45),
                              axis: (x: 1.0, y: 0.0, z: 0.0)
            )
        }
        .animation(.easeInOut(duration: 0.8).delay(0.8), value: animated)
      }

      Spacer()

      Divider()
        .opacity(animated ? 1 : 0)
        .animation(.easeInOut(duration: 1.5).delay(1.5), value: animated)
      HStack(spacing: 16) {
        Button("View source code", action: {
          onAction(.github)
        })
          .buttonStyle(.plain)
        Spacer()
        Button("Request permission", action: {
          done.toggle()
          onAction(.requestPermissions)
        })
          .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, hoverEffect: false)))
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
    .frame(maxHeight: .infinity)
    .background(SplashView(done: $done))
    .onAppear {
      animated = true
    }
  }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
      PermissionsView(onAction: { _ in })
    }
}
