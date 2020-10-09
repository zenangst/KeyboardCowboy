import SwiftUI

public class UserSelection: ObservableObject {
  @Published public var group: GroupViewModel?
  @Published public var workflow: WorkflowViewModel?

  public init() {}
}
