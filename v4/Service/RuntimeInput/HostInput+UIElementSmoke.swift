#if DEBUG
import AccessibilitySystem
import AppKit
import ApplicationServices
import OSLog
import UIElementFeature

package extension HostInput {
  @MainActor
  static func smokeUIElement(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "UIElementSmoke")
    let miss = arguments == ["--miss"]
    let inspect = arguments == ["--inspect"]
    guard arguments.isEmpty || miss || inspect else {
      log.notice("Expected --smoke-ui-element [--miss | --inspect]")
      return
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }
    guard let safari = NSWorkspace.shared.frontmostApplication,
          safari.bundleIdentifier == "com.apple.Safari" else {
      log.notice("No action: focus a Safari window first")
      return
    }

    let labels = miss ? ["Keyboard Cowboy smoke: \(UUID().uuidString)"] : ["Sidebar", "sidebar"]
    let predicates = labels.map {
      UIElement.Predicate(role: "AXButton", properties: [.description, .title], comparison: .contains, value: $0)
    }
    do {
      if inspect {
        log.notice("Hover over Show Sidebar within five seconds; no control will be pressed")
        try await Task.sleep(for: .seconds(5))
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == safari.processIdentifier,
              let point = CGEvent(source: nil)?.location else {
          log.notice("Inspection skipped: focus Safari and hover over Show Sidebar")
          return
        }
        let client = AccessibilitySystem.Client()
        let (role, labelMatches) = try await client.withElement(at: point) { hit in
          let role = try hit.read(.role)
          let names = [try? hit.read(.accessibilityDescription), try? hit.read(.title)].compactMap { $0 }
          return (role, names.contains { name in labels.contains { name.contains($0) } })
        }
        log.notice("Hovered role: \(role, privacy: .public); label matches sidebar predicate: \(labelMatches, privacy: .public)")
        let pid = safari.processIdentifier
        let (hasWindow, hasMatch) = try await client.withApplication(processIdentifier: pid) { session in
          guard let window = try UIElement.focusedWindow(inFrontmostApplication: session) else { return (false, false) }
          return (true, try UIElement.firstMatch(in: session, under: window, predicates: predicates) != nil)
        }
        log.notice("Focused window resolved: \(hasWindow, privacy: .public); predicate found in window: \(hasMatch, privacy: .public)")
        return
      }
      let activated = try await UIElement.activate(predicates: predicates)
      log.notice("UIElement activated: \(activated, privacy: .public); intentional miss: \(miss, privacy: .public)")
    } catch let failure as AccessibilitySystem.Failure {
      log.error("UIElement activation failed: \(failure.operation, privacy: .public) \(String(describing: failure.kind), privacy: .public)")
    } catch {
      log.error("UIElement activation failed")
    }
  }
}
#endif
