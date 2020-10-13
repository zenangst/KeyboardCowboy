import ViewKit
import LogicFramework
import Combine
import ModelKit

class ApplicationsProvider: StateController {
  @Published var state: [Application] = []

  init(applications: [Application]) {
    self.state = applications
  }
}
