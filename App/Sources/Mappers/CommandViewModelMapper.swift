import Foundation
import LogicFramework
import ViewKit

class CommandViewModelMapper {
  func map(_ models: [Command]) -> [CommandViewModel] {
    models.compactMap(map(_:))
  }

  func map(_ command: Command) -> CommandViewModel {
    .init(name: UUID().uuidString)
  }
}
