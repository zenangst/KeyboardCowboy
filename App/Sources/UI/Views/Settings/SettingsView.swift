import Inject
import SwiftUI

struct SettingsView: View {
  @ObserveInjection var inject
  var body: some View {
    TabView {
      ApplicationSettingsView()
        .tabItem { Label("Applications", systemImage: "appclip") }
      NotificationsSettingsView()
        .tabItem { Label("Notifications", systemImage: "app.badge") }
      PermissionsSettingsView()
        .tabItem { Label("Permissions", systemImage: "hand.raised.circle.fill") }
    }
    .enableInjection()
  }
}
