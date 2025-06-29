import Bonzai
import SwiftUI

struct GeneralSettingsView: View {
  @ObserveInjection private var inject
  @StateObject var loginItem = LoginItem()
  @StateObject var appUpdater = AppUpdater()
  @AppStorage("showMenuBarIcon") private var showMenuBarIcon: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
        GridRow {
          SettingsIcon(NSColor.red, symbolName: "gearshape.2")
          Text("Launch at Login")
            .frame(maxWidth: .infinity, alignment: .leading)
          Toggle(isOn: $loginItem.isEnabled, label: {})
        }
        .padding(8)

        Divider()

        GridRow {
          SettingsIcon(NSColor.orange, symbolName: "menubar.arrow.up.rectangle")
          Text("Show menu bar icon")
            .frame(maxWidth: .infinity, alignment: .leading)
          Toggle(isOn: $showMenuBarIcon) { }
        }
        .padding(8)
      }
      .roundedStyle(padding: 0)

      Spacer()

      Button { appUpdater.checkForUpdates() } label: { Text("Check for updates…") }
    }
    .switchStyle()
    .padding(8)
    .frame(width: 600)
    .style(.section(.detail))
    .padding(.bottom, 16)
    .enableInjection()
  }
}

#Preview {
  GeneralSettingsView()
}
