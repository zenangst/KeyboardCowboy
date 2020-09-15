import XCTest
import Cocoa
import SwiftUI
import SnapshotTesting
@testable import ViewKit

extension XCTestCase {
  func assertPreview<Provider: TestPreviewProvider>(
    from provider: Provider.Type,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    assertPreview(
      provider.testPreview,
      size: size,
      file: file,
      testName: testName,
      line: line
    )
  }

  func assertPreview<T: View>(
    _ view: T,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
  ) {
    let info = ProcessInfo.processInfo
    let version = "\(info.operatingSystemVersion.majorVersion).\(info.operatingSystemVersion.minorVersion)"

    for scheme in ColorScheme.allCases {
      let view = view
        .previewLayout(.sizeThatFits)
        .colorScheme(scheme)
        .environment(\.sizeCategory, .accessibilityMedium)

      assertSnapshot(
        matching: SnapshotWindow(view, size: size).viewController,
        as: .image,
        named: "macOS\(version)-\(scheme.name)",
        file: file,
        testName: testName,
        line: line
      )
    }
  }
}

// MARK: - Private

private class SnapshotWindow<Content>: NSWindow where Content: View {
  let viewController: NSViewController

  init(_ view: Content, size: CGSize) {
    let viewController = NSHostingController(rootView: view)
    viewController.view.wantsLayer = true
    viewController.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    self.viewController = viewController
    super.init(contentRect: .zero,
               styleMask: [.closable, .miniaturizable, .resizable],
               backing: .buffered, defer: false)
    self.contentViewController = viewController
    setFrame(.init(origin: .zero, size: size), display: true)
  }
}

private extension ColorScheme {
  var name: String {
    String(describing: self).capitalized
  }
}
