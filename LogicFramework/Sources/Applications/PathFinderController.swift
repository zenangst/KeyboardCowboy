import Foundation
import ModelKit

/// Make sure that all current path reference are correct for the persisted groups
public class PathFinderController {
  public init() {}

  public func patch(_ groups: [Group], applications: [Application]) -> [Group] {
    var appDictionary = [String: Application]()
    for app in applications {
      appDictionary[app.bundleIdentifier] = app
    }

    var groups = groups
    for (gOffset, group) in groups.enumerated() {
      for (wOffset, workflow) in group.workflows.enumerated() {
        for (cOffset, command) in workflow.commands.enumerated() {

          if case .application(let appCommand) = command,
             let installedApplication = appDictionary[appCommand.application.bundleIdentifier] {

            var newApplication = Application(
              id: appCommand.application.id,
              bundleIdentifier: installedApplication.bundleIdentifier,
              bundleName: installedApplication.bundleName,
              path: installedApplication.path)
            newApplication.isElectronApp = installedApplication.isElectronApp

            let newCommand = Command.application(.init(
              id: appCommand.id,
              name: appCommand.name,
              application: newApplication
            ))

            groups[gOffset].workflows[wOffset].commands[cOffset] = newCommand
          }
        }
      }
    }

    return groups
  }
}
