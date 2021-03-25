import XCTest
import Cocoa
import SwiftUI
import SnapshotTesting
@testable import ViewKit

extension XCTestCase {
  func assertScreenshot<Provider: TestPreviewProvider>(
    from provider: Provider.Type,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line,
    redacted: Bool = true,
    transparent: Bool = false
  ) {
    assertScreenshot(
      provider.testPreview,
      size: size,
      file: file,
      testName: testName,
      line: line,
      redacted: redacted,
      transparent: transparent
    )
  }

  func assertScreenshot<T: View>(
    _ view: T,
    size: CGSize,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line,
    redacted: Bool = true,
    transparent: Bool = false
  ) {
    let info = ProcessInfo.processInfo
    let version = "\(info.operatingSystemVersion.majorVersion).\(info.operatingSystemVersion.minorVersion)"

    for scheme in ColorScheme.allCases {
      let anyView: AnyView

      if redacted {
        anyView = AnyView(view
          .previewLayout(.sizeThatFits)
          .background(Color( transparent ? .clear : .windowBackgroundColor))
          .colorScheme(scheme)
          .redacted(reason: .placeholder))
      } else {
        anyView = AnyView(view
          .previewLayout(.sizeThatFits)
          .background(Color( transparent ? .clear : .windowBackgroundColor))
          .colorScheme(scheme))
      }

      let window = SnapshotWindow(anyView, size: size)
      let expectation = self.expectation(description: "Wait for window to load")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        assertSnapshot(
          matching: window.viewController,
          as: .image(precision: 1.0),
          named: "macOS\(version)-\(scheme.name)",
          file: file,
          testName: testName,
          line: line
        )
        expectation.fulfill()
      }

      wait(for: [expectation], timeout: 10.0)
    }
  }
}

// MARK: - Private

private class SnapshotWindow<Content>: NSWindow where Content: View {
  let viewController: NSViewController

  init(_ view: Content, size: CGSize) {
    let viewController = NSHostingController(rootView: view)
    self.viewController = viewController
    super.init(contentRect: .zero,
               styleMask: [.closable, .miniaturizable, .resizable],
               backing: .buffered, defer: false)
    self.contentViewController = viewController
    setFrame(.init(origin: .zero, size: size), display: true)
    backgroundColor = .clear
  }
}

private extension ColorScheme {
  var name: String {
    String(describing: self).capitalized
  }
}
