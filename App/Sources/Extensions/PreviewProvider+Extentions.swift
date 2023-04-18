import SwiftUI

extension PreviewProvider {
  static var applicationStore: ApplicationStore { contentStore.applicationStore }
  static var configurationStore: ConfigurationStore { contentStore.configurationStore }
  static var contentStore: ContentStore {
    ContentStore(
      .designTime(),
      applicationStore: applicationStore,
      keyboardShortcutsCache: KeyboardShortcutsCache(),
      shortcutStore: .init(engine: ScriptEngine(workspace: .shared)),
      scriptEngine: .init(workspace: .shared),
      workspace: .shared)
  }
  static var groupStore: GroupStore { contentStore.groupStore }
  static func autoCompletionStore(_ completions: [String],
                                  selection: String? = nil) -> AutoCompletionStore {
    AutoCompletionStore(completions, selection: selection)
  }
}
