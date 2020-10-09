import Foundation

public struct OpenURLViewModel: Identifiable, Hashable {
  public let id: String
  public let url: URL
  public let application: ApplicationViewModel?

  public init(id: String = UUID().uuidString, url: URL,
              application: ApplicationViewModel? = nil) {
    self.id = id
    self.url = url
    self.application = application
  }
}

extension OpenURLViewModel {
  static func empty() -> OpenURLViewModel {
    OpenURLViewModel(url: URL(string: "https://apple.com")!,
                      application: nil)
  }
}
