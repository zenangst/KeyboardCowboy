import Foundation

final class MacroRunner {
  private let coordinator: MacroCoordinator

  init(coordinator: MacroCoordinator) {
    self.coordinator = coordinator
  }

  func run(_ macroAction: MacroAction) async -> String {
    ""
  }
}
