import SwiftUI
import ModelKit

public class UserSelection: ObservableObject {
  @Published public var group: ModelKit.Group?
  @Published public var workflow: Workflow?

  public init() {}
}
