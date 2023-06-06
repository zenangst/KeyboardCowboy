import SwiftUI

struct SidebarConfigurationHeaderView: View {
  var body: some View {
    Label("Configuration", image: "")
      .padding(.top, 6)
  }
}

struct ConfigurationHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    SidebarConfigurationHeaderView()
  }
}
