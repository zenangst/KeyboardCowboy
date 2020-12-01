import SwiftUI
import ModelKit

public class UserSelection: ObservableObject {
  @Published public var group: ModelKit.Group?
  @Published public var workflow: Workflow?
  @Published public var searchQuery: String = ""
  @Published public var hasPrivileges: Bool

  public init(group: ModelKit.Group? = nil, workflow: ModelKit.Workflow? = nil,
              hasPrivileges: Bool = false) {
    self.group = group
    self.workflow = workflow
    self.hasPrivileges = hasPrivileges
  }
}
