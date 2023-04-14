import SwiftUI
import ViewKit

struct KeyboardCowboySettingsView: View {
  private enum Tabs: Hashable {
    case general, advanced
  }

  var body: some View {
    TabView {
      GeneralSettings().tag(Tabs.general)
    }.padding()
    .frame(width: 350, height: 200)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    KeyboardCowboySettingsView()
  }
}
