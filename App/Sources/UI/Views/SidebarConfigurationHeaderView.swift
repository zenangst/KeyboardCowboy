import Bonzai
import SwiftUI

struct SidebarConfigurationHeaderView: View {
  var body: some View {
    ZenLabel(.sidebar) { Text("Configuration") }
      .padding(.top, 6)
  }
}

struct ConfigurationHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationHeaderView()
  }
}
