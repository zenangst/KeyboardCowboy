import Inject
import SwiftUI

struct SettingsView: View {
  @ObserveInjection var inject
  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem { Label("Applications", systemImage: "app") }
      ApplicationSettingsView()
        .tabItem { Label("Applications", systemImage: "appclip") }
      NotificationsSettingsView()
        .tabItem { Label("Notifications", systemImage: "app.badge") }
      PermissionsSettingsView()
        .padding(8)
        .tabItem { Label("Permissions", systemImage: "hand.raised.circle.fill") }
    }
    .frame(minWidth: 450, minHeight: 280, alignment: .center)
    .enableInjection()
  }
}
