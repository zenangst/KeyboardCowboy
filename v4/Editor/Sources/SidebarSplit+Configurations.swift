import SwiftUI

extension SidebarSplit {
  @Injectable
  struct Configurations: View {

    var content: some View {
      VStack {
        Label("Configurations")

        ConfigurationsMenu()
      }
    }
  }
}
