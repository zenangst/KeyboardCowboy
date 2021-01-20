import Combine
import Foundation
import ModelKit
import ViewKit
import SwiftUI
import LogicFramework

class QuickRunFeatureController: ViewController {
  var window: NSWindow?
  var storage = [Workflow]() {
    didSet {
      state = storage
    }
  }
  @Published var state = [Workflow]()
  @Published var query: String = "" {
    willSet {
      if newValue.isEmpty {
        state = storage
      } else {
        state = storage.filter({ $0.name.lowercased().contains(newValue.lowercased()) })
      }
    }
  }

  var commandController: CommandControlling

  init(commandController: CommandControlling) {
    self.commandController = commandController
  }

  func perform(_ action: QuickRunView.Action) {
    switch action {
    case .run(let workflowId):
      guard let workflow = state.first(where: { $0.id == workflowId}) else { return }
      commandController.run(workflow.commands)
      window?.close()
    }
  }
}
