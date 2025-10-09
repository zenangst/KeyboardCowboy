import ApplicationServices
import Foundation

struct UIElementCommand: MetaDataProviding {
  var placeholder: String {
    predicates.count > 1
      ? "Tap on UI Elements …"
      : "Tap on UI Element …"
  }

  var meta: Command.MetaData
  var predicates: [Predicate]

  init(meta: Command.MetaData = .init(), predicates: [Predicate]) {
    self.meta = meta
    self.predicates = predicates
  }

  func copy() -> UIElementCommand {
    UIElementCommand(meta: meta.copy(), predicates: predicates.copy())
  }
}

extension Collection<UIElementCommand.Predicate> {
  func copy() -> [UIElementCommand.Predicate] {
    map { $0.copy() }
  }
}
