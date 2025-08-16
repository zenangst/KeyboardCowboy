import Cocoa

final class OpenURLParser: Sendable {
  func parse(_ path: String) -> URL {
    let targetUrl: URL

    if let url = URL(string: path) {
      if url.scheme == nil || url.isFileURL {
        targetUrl = URL(fileURLWithPath: path)
      } else {
        targetUrl = url
      }
    } else {
      targetUrl = URL(fileURLWithPath: path)
    }

    return targetUrl
  }
}
