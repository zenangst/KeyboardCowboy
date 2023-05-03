import SwiftUI

extension View {
  @MainActor
  func designTime() -> some View {
   self
      .environmentObject(DesignTime.configurationPublisher)
      .environmentObject(DesignTime.contentPublisher)
      .environmentObject(DesignTime.detailStatePublisher)
      .environmentObject(DesignTime.detailPublisher)
      .environmentObject(DesignTime.groupsPublisher)
      .environmentObject(KeyShortcutRecorderStore())
      .environmentObject(ApplicationStore())
      .environmentObject(ShortcutStore(engine: ScriptEngine(workspace: .shared)))
  }
}
