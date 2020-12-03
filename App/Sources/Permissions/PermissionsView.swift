import SwiftUI

struct PermissionsView: View {
  var body: some View {
    ZStack {
      Color(.windowBackgroundColor)
      VStack {
        Image("ApplicationIcon")
          .resizable()
          .frame(width: 256, height: 256)
        Text(appDelegate.permissionController.informativeText)
      }
    }
  }
}
