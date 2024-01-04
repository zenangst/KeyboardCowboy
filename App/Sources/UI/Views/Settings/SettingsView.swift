import SwiftUI

struct SettingsView: View {
  var body: some View {
    TabView {
      ApplicationSettingsView()
        .tabItem { Label("Applications", systemImage: "appclip") }
      NotificationsSettingsView()
        .tabItem { Label("Notifications", systemImage: "app.badge") }
      PermissionsSettings()
        .tabItem { Label("Permissions", systemImage: "hand.raised.circle.fill") }
    }
  }
}
