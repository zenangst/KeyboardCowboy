import Dispatch
import Foundation

enum FileWatcherError: Error {
  case fileNotFound
}

final class FileWatcher {
  let fileSystemMonitor: DispatchSourceFileSystemObject

  init(_ fileURL: URL, handler: @escaping (URL) -> Void) throws {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw FileWatcherError.fileNotFound
    }

    let handle = open(fileURL.path, O_EVTONLY)
    let eventMask: DispatchSource.FileSystemEvent = [
      .delete, .write, .extend, .attrib, .link, .rename, .revoke
    ]
    let fileSystemMonitor = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: handle,
      eventMask: eventMask,
      queue: .main
    )

    self.fileSystemMonitor = fileSystemMonitor

    fileSystemMonitor.setEventHandler(handler: {
      handler(fileURL)
    })
  }

  func start() {
    fileSystemMonitor.resume()
  }

  func stop() {
    fileSystemMonitor.cancel()
  }
}
