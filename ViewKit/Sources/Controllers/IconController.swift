import Cocoa
import ModelKit
import SwiftUI

public class IconController {
  public var applications: [Application]
  private(set) public static var shared: IconController = .init(applications: [])

  private init(applications: [Application]) {
    self.applications = applications
  }

  func createIconView(_ bundleIdentifier: String) -> IconView? {
    if let path = applications.first(where: { $0.bundleIdentifier == bundleIdentifier })?.path {
      return IconView(path: path)
    }
    return nil
  }
}
