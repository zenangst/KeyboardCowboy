import ViewKit
import LogicFramework
import Combine
import ModelKit

class ApplicationsProvider: StateController {
  @Published var state: [ApplicationViewModel] = []
  let mapper: ApplicationViewModelMapping

  init(applications: [Application], mapper: ApplicationViewModelMapping) {
    self.mapper = mapper
    self.state = mapper.map(applications)
  }
}
