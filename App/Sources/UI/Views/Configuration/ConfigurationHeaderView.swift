import Bonzai
import SwiftUI

struct ConfigurationHeaderView: View {
  var body: some View {
    ZenLabel(.sidebar) { Text("Configuration") }
  }
}

struct ConfigurationHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    ConfigurationHeaderView()
  }
}
