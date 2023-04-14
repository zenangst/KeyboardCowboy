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
        state = storage
          .filter({ $0.name.lowercased().contains(newValue.lowercased()) })
          .unique(by: { $0.name })
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

private extension Array {
    func unique<T: Hashable>(by: ((Element) -> (T))) -> [Element] {
        var set = Set<T>()
        var arrayOrdered = [Element]()
        for value in self {
            if !set.contains(by(value)) {
                set.insert(by(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
