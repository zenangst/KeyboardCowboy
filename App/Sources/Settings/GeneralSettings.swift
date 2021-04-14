import SwiftUI

struct GeneralSettings: View {
  @AppStorage("openWindowOnLaunch") var openWindowOnLaunch = false
  @AppStorage("hideMenuBarIcon") var hideMenubarIcon = false
  @AppStorage("hideDockIcon") var hideDockIcon = false

  var body: some View {
    Form {
      VStack(alignment: .center) {
        VStack(alignment: .leading) {
          Toggle("Open window on application launch", isOn: $openWindowOnLaunch)
          Toggle("Hide Keyboard Cowboy in the Dock", isOn: $hideDockIcon)
          Toggle("Hide Keyboard Cowboy in the menu bar", isOn: $hideMenubarIcon)
          Text("""
        If you hide the icon in both the Dock and the menu bar, you can access it by double-clicking its application icon in the Finder.
        """).font(.caption)
        }
        Divider()
      }
    }.tabItem {
      Label("General", image: "Menubar_active")
    }
  }
}

struct GeneralSettings_Previews: PreviewProvider {
  static var previews: some View {
    GeneralSettings()
  }
}
