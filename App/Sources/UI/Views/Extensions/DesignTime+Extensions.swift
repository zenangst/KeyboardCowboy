import SwiftUI

extension View {
  @MainActor
  func designTime() -> some View {
   self
      .environmentObject(DesignTime.configurationPublisher)
      .environmentObject(DesignTime.contentPublisher)
      .environmentObject(DesignTime.detailStatePublisher)
      .environmentObject(DesignTime.groupsPublisher)
      .environmentObject(DesignTime.groupPublisher)
      .environmentObject(DesignTime.infoPublisher)
      .environmentObject(DesignTime.triggerPublisher)
      .environmentObject(DesignTime.commandsPublisher)
      .environmentObject(KeyShortcutRecorderStore())
      .environmentObject(ApplicationStore.shared)
      .environmentObject(ShortcutStore(ScriptCommandRunner(workspace: .shared)))
  }
}
