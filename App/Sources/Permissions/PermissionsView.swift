import SwiftUI

struct PermissionsView: View {
  let text: String

  var body: some View {
    ZStack {
      Color(.windowBackgroundColor)
      VStack {
        Image("ApplicationIcon")
          .resizable()
          .frame(width: 256, height: 256)
        Text(text)
      }
    }
  }
}
