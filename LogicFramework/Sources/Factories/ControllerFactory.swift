import Foundation

public class ControllerFactory {
  public func commandController(
    applicationCommandController: ApplicationCommandControlling? = nil
  ) -> CommandControlling {
    let applicationCommandController = applicationCommandController ?? ApplicationCommandController()
    return CommandController(applicationCommandController: applicationCommandController)
  }
}
