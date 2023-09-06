import SwiftUI

extension PreviewProvider {
  static var applicationStore: ApplicationStore { contentStore.applicationStore }
  static var configurationStore: ConfigurationStore { contentStore.configurationStore }
  static var contentStore: ContentStore {
    ContentStore(.designTime(), applicationStore: Self.applicationStore,
                 configurationStore: Self.configurationStore, groupStore: GroupStore(),
                 keyboardShortcutsController: KeyboardShortcutsController(),
                 recorderStore: KeyShortcutRecorderStore(),
                 shortcutStore: ShortcutStore(.init(workspace: .shared)))
  }
  static var groupStore: GroupStore { contentStore.groupStore }
  static func autoCompletionStore(_ completions: [String],
                                  selection: String? = nil) -> AutoCompletionStore {
    AutoCompletionStore(completions, selection: selection)
  }
}
