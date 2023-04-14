import SwiftUI

struct PermissionsView: View, Equatable {
  let text: String

  var body: some View {
    VStack(alignment: .center) {
      HStack(alignment: .top, spacing: 32) {
        Image("ApplicationIcon")
          .resizable()
          .frame(width: 196, height: 196)
          .offset(x: 0, y: -24)
        VStack {
          Text(text)
          Button("Quit") {
            NSApplication.shared.terminate(nil)
          }
          .keyboardShortcut(.defaultAction)
          .padding()
        }
      }
    }
    .padding([.leading, .trailing])
  }
}
