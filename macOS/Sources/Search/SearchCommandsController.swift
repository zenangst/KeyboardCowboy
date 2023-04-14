import Foundation
import ModelKit
import ViewKit
import SwiftUI
import Combine

final class SearchCommandsController: StateController {
  @Published var state = ModelKit.SearchResult.commands([])
  let searchWorkflowController: SearchWorkflowController
  var query: String = ""
  var anyCancellables = [AnyCancellable]()

  init(searchWorkflowController: SearchWorkflowController) {
    self.searchWorkflowController = searchWorkflowController

    searchWorkflowController.$state
      .dropFirst()
      .sink(receiveValue: { [weak self] results in
      guard let self = self,
            case .workflows(let workflows) = results else { return }
      let commands = workflows.flatMap({ self.searchForCommandsByName(self.query, workflow: $0) })
      self.state = .commands(commands)
    }).store(in: &anyCancellables)
  }

  private func searchForCommandsByName(_ query: String,
                                       workflow: ModelKit.Workflow) -> [ModelKit.Command] {
    workflow.commands.filter {
      $0.name.containsCaseSensitive(query)
    }
  }
}
