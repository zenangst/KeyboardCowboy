import Foundation
import ModelKit
import LogicFramework
import Cocoa

class ApplicationController {
  static func commonPaths() -> [URL] {
    var urls = [URL]()
    if let userDirectory = try? FileManager.default.url(for: .applicationDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: false) {
      urls.append(userDirectory)
    }
    if let applicationDirectory = try? FileManager.default.url(for: .allApplicationsDirectory,
                                                               in: .localDomainMask,
                                                               appropriateFor: nil,
                                                               create: false) {
      urls.append(applicationDirectory)
    }

    if let coreServices = try? FileManager.default.url(for: .coreServiceDirectory,
                                                       in: .systemDomainMask,
                                                       appropriateFor: nil,
                                                       create: false) {
      urls.append(coreServices)
    }

    let applicationDirectoryD = URL(fileURLWithPath: "/Developer/Applications")
    let applicationDirectoryN = URL(fileURLWithPath: "/Network/Applications")
    let applicationDirectoryND = URL(fileURLWithPath: "/Network/Developer/Applications")
    let applicationDirectoryS = URL(fileURLWithPath: "/Users/Shared/Applications")
    let systemApplicationsDirectory = URL(fileURLWithPath: "/System/Applications")

    urls.append(contentsOf: [applicationDirectoryD, applicationDirectoryN,
                             applicationDirectoryND, applicationDirectoryS,
                             systemApplicationsDirectory])

    return urls
  }

  static func loadApplications() -> [Application] {
    let urls: [URL] = Self.commonPaths()
    let fileIndexer = FileIndexController(urls: urls)
    var patterns = FileIndexPatternsFactory.patterns()
    patterns.append(contentsOf: FileIndexPatternsFactory.pathExtensions())
    patterns.append(contentsOf: FileIndexPatternsFactory.lastPathComponents())

    let applicationParser = ApplicationParser()
    let result = fileIndexer.index(with: patterns, match: {
      $0.absoluteString.hasSuffix(".app/")
    }, handler: applicationParser.process(_:))
    .sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })

    return result
  }
}
