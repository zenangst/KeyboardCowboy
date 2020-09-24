import Foundation
import LogicFramework
import ViewKit

class CombinationViewModelMapper {
  func map(_ keyboardShortcut: [KeyboardShortcut]) -> [CombinationViewModel] {
    keyboardShortcut.compactMap { .init(name: $0.key) }
  }
}
