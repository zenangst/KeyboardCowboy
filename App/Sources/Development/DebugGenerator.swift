import Foundation
import SwiftUI

final class DebugGenerator {
  @EnvironmentObject var applicationStore: ApplicationStore

  @MainActor
  static func fillGroupStoreWithWorkflows(_ groupStore: GroupStore, applicationStore: ApplicationStore) {
    var updatedGroups = Set<WorkflowGroup>()
    updatedGroups.reserveCapacity(groupStore.groups.count)

    for group in groupStore.groups {
      var copy = group
      let appsCount = applicationStore.applications.count
      (0..<1).forEach { x in
        var workflow = Workflow(name: "Performance workflow \(x)")
        (0..<150).forEach { y in
          let randomApp = applicationStore.applications[Int.random(in: 0..<appsCount)]
          let command: Command = .application(
            ApplicationCommand(name: "Application command: \(y)", application: randomApp)
          )
          workflow.commands.append(command)
        }
        copy.workflows.append(workflow)
      }
      updatedGroups.insert(copy)
    }

    groupStore.updateGroups(updatedGroups)
  }
}
