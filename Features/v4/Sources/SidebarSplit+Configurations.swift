import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct Configurations: View {
    @ObserveInjection private var inject

    var body: some View {
      VStack {
        Label("Configurations")

        ConfigurationsMenu()
      }
      .enableInjection()
    }
  }
}
