import SwiftUI

extension View {
  func designTime() -> some View {
   self
      .environmentObject(DesignTime.configurationPublisher)
      .environmentObject(DesignTime.contentPublisher)
      .environmentObject(DesignTime.detailPublisher)
      .environmentObject(DesignTime.groupsPublisher)
      .environmentObject(ApplicationStore())
  }
}
