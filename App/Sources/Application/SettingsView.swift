import SwiftUI

struct SettingsView: View {
  @AppStorage("hideMenuBarIcon") var hideMenubarIcon = false
  @AppStorage("hideDockIcon") var hideDockIcon = false

  var body: some View {
    VStack(alignment: .center) {
      VStack(alignment: .leading) {
        Toggle("Hide Keyboard Cowboy in the Dock", isOn: $hideDockIcon)
        Toggle("Hide Keyboard Cowboy in the menu bar", isOn: $hideMenubarIcon)
        Text("""
        If you hide the icon in both the Dock and the menu bar, you can access it by double-clicking its application icon in the Finder.
        """).font(.caption)
      }
      Divider()
    }
    .padding()
    .frame(width: 350, height: 250, alignment: .center)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
