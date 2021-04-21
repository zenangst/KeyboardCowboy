import Foundation
import LogicFramework
import ViewKit
import Combine
import Cocoa
import ModelKit

protocol ApplicationTriggerFeatureControllerDelegate: AnyObject {
  func applicationTriggerFeatureContorller(_ controller: ApplicationTriggerFeatureController,
                                           didCreateEmptyApplicationTrigger: Workflow.Trigger,
                                           in workflow: Workflow)
  func applicationTriggerFeatureController(_ controller: ApplicationTriggerFeatureController,
                                           didApplicationTrigger applicationTrigger: ApplicationTrigger,
                                           in workflow: Workflow)
  func applicationTriggerFeatureController(_ controller: ApplicationTriggerFeatureController,
                                           didUpdateApplicationTrigger applicationTrigger: ApplicationTrigger,
                                           in workflow: Workflow)
  func applicationTriggerFeatureController(_ controller: ApplicationTriggerFeatureController,
                                           didDeleteApplicationTrigger applicationTrigger: ApplicationTrigger,
                                           in workflow: Workflow)
  func applicationTriggerFeatureController(_ controller: ApplicationTriggerFeatureController,
                                           didClearTrigger trigger: Workflow.Trigger,
                                           in workflow: Workflow)

}

final class ApplicationTriggerFeatureController: ActionController {
  weak var delegate: ApplicationTriggerFeatureControllerDelegate?

  func perform(_ action: ApplicationTriggerList.UIAction) {
    switch action {
    case .create(let applicationTrigger, let offset, let workflow):
      create(applicationTrigger, at: offset, in: workflow)
    case .update(let applicationTrigger, let workflow):
      update(applicationTrigger, in: workflow)
    case .delete(let applicationTrigger, let workflow):
      delete(applicationTrigger, in: workflow)
    case .move(let applicationTrigger, let offset, let workflow):
      move(applicationTrigger, to: offset, in: workflow)
    case .emptyTrigger(var workflow):
      let trigger: Workflow.Trigger = .application([])
      workflow.trigger = trigger
      delegate?.applicationTriggerFeatureContorller(self, didCreateEmptyApplicationTrigger: trigger, in: workflow)
    case .clear(var workflow):
      guard let trigger = workflow.trigger else { return }
      workflow.trigger = nil
      delegate?.applicationTriggerFeatureController(self, didClearTrigger: trigger, in: workflow)
    }
  }

  // MARK: Private methods

  func create(_ trigger: ApplicationTrigger, at index: Int, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case .application(var applicationTriggers):
      applicationTriggers.add(trigger, at: index)
      workflow.trigger = .application(applicationTriggers)
    default: break
    }

    delegate?.applicationTriggerFeatureController(self, didApplicationTrigger: trigger, in: workflow)
  }

  func update(_ trigger: ApplicationTrigger, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case .application(var applicationTriggers):
      try? applicationTriggers.replace(trigger)
      workflow.trigger = .application(applicationTriggers)
    default:
      break
    }

    delegate?.applicationTriggerFeatureController(self, didUpdateApplicationTrigger: trigger, in: workflow)
  }

  func delete(_ trigger: ApplicationTrigger, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case .application(var applicationTriggers):
      try? applicationTriggers.remove(trigger)
      workflow.trigger = .application(applicationTriggers)
    default:
      break
    }

    delegate?.applicationTriggerFeatureController(self, didDeleteApplicationTrigger: trigger, in: workflow)
  }

  func move(_ trigger: ApplicationTrigger, to offset: Int, in workflow: Workflow) {
    var workflow = workflow

    switch workflow.trigger {
    case .application(var applicationTriggers):
      guard let currentIndex = applicationTriggers.firstIndex(of: trigger) else { return }
      let newIndex = currentIndex + offset
      try? applicationTriggers.move(trigger, to: newIndex)
      workflow.trigger = .application(applicationTriggers)
    default:
      break
    }

    delegate?.applicationTriggerFeatureController(self, didApplicationTrigger: trigger, in: workflow)
  }
}
