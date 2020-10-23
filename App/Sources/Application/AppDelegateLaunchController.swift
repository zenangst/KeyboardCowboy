import Cocoa
import LaunchArguments
import LogicFramework

final class AppDelegateLaunchController {
  let factory: ControllerFactory

  init(factory: ControllerFactory) {
    self.factory = factory
  }

  /// Construct the applications `CoreController` and configure it using
  /// launch arguments.
  ///
  /// - Parameter storageController: The storage controller that is used to load
  ///                                information from disk.
  /// - Throws: If the storage cannot be loaded properly, this method will throw
  ///           a `StorageControllingError`
  /// - Returns: A controller that conforms to `CoreControlling`
  func initialLoad(storageController: StorageControlling) throws -> CoreControlling {
    let groups = try storageController.load()
    let groupsController = factory.groupsController(groups: groups)
    let controller = factory.coreController(
      disableKeyboardShortcuts: launchArguments.isEnabled(.disableKeyboardShortcuts),
      groupsController: groupsController)
    return controller
  }
}
