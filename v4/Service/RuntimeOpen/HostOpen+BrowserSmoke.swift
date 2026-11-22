#if DEBUG
import AppKit
import ApplicationServices
import Commands
import OSLog

package extension HostOpen {
  @MainActor
  static func smokeBrowser(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "BrowserSmoke")
    if arguments == ["--check-accessibility"] {
      log.notice("Accessibility trusted: \(AXIsProcessTrusted(), privacy: .public)")
      return
    }
    guard arguments.count == 2,
          let url = URL(string: arguments[1]),
          let scheme = url.scheme?.lowercased(),
          ["http", "https"].contains(scheme), url.host != nil
    else {
      log.notice("Expected --smoke-open-browser <bundle-id> <http-or-https-url>")
      return
    }

    let identifier = arguments[0]
    guard let browserURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier),
          let bundle = Bundle(url: browserURL),
          NSRunningApplication.runningApplications(withBundleIdentifier: identifier).contains(where: { !$0.isTerminated }),
          let hostIdentifier = Bundle.main.bundleIdentifier,
          identifier != hostIdentifier,
          !identifier.hasPrefix("com.apple.Safari.WebApp"),
          !identifier.hasPrefix("com.kagi.kagimacOS.WebApp"),
          identifier.lowercased() != "com.apple.finder"
    else {
      log.notice("Expected an installed, running browser")
      return
    }

    log.notice("Accessibility trusted: \(AXIsProcessTrusted(), privacy: .public)")
    let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? browserURL.deletingPathExtension().lastPathComponent
    let command = Command.Open(
      application: .init(bundleIdentifier: identifier, bundleName: name, path: browserURL.path),
      path: arguments[1],
    )
    let open = HostOpen(
      hostBundleIdentifier: hostIdentifier,
      hostBundleURL: Bundle.main.bundleURL,
      openHost: { log.error("Unexpected host route") },
      openWebApp: { _, _, _ in log.error("Unexpected web-app route") },
      record: { log.notice("\($0.rawValue, privacy: .public)") },
    )
    do {
      try await open.run(command, resolvedPath: command.path, checkCancellation: true)
      log.notice("Open command completed")
    } catch {
      log.error("Open command failed")
    }
  }
}
#endif
