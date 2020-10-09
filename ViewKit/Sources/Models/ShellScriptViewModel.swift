import Foundation

public struct ShellScriptViewModel: Identifiable, Hashable {
  public let id: String
  public let path: String

  public init(id: String = UUID().uuidString, path: String) {
    self.id = id
    self.path = path
  }
}

extension ShellScriptViewModel {
  static func empty() -> ShellScriptViewModel {
    ShellScriptViewModel(id: UUID().uuidString, path: "")
  }
}
