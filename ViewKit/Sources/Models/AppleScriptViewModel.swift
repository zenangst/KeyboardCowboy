import Foundation

public struct AppleScriptViewModel: Identifiable, Hashable {
  public let id: String
  public let path: String

  public init(id: String = UUID().uuidString, path: String) {
    self.id = id
    self.path = path
  }
}

extension AppleScriptViewModel {
  static func empty() -> AppleScriptViewModel {
    AppleScriptViewModel(id: UUID().uuidString, path: "")
  }
}
