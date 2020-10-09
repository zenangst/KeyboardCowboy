import Foundation

public struct OpenFileViewModel: Identifiable, Hashable {
  public let id: String
  public let path: String
  public let application: ApplicationViewModel?

  public init(id: String = UUID().uuidString,
              path: String,
              application: ApplicationViewModel? = nil) {
    self.id = id
    self.path = path
    self.application = application
  }
}

extension OpenFileViewModel {
  static func empty() -> OpenFileViewModel {
    OpenFileViewModel(path: "", application: nil)
  }
}
