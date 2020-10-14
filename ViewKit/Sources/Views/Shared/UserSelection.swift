import SwiftUI
import ModelKit

public class UserSelection: ObservableObject {
  @Published public var group: ModelKit.Group? {
    didSet { workflow = group?.workflows.first }
  }
  @Published public var workflow: Workflow?

  public init() {}
}
