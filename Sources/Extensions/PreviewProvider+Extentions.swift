import SwiftUI

extension PreviewProvider {
  static var applicationStore: ApplicationStore { contentStore.applicationStore }
  static var configurationStore: ConfigurationStore { contentStore.configurationStore }
  static var contentStore: ContentStore { ContentStore(undoManager: nil) }
  static var groupStore: GroupStore { contentStore.groupStore }
}
