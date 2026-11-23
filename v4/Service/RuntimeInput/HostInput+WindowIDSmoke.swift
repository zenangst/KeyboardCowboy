#if DEBUG
import AccessibilitySystem
import AppKit
import ApplicationServices
import OSLog

extension HostInput {
  struct WindowIDCheck: Equatable {
    var matched = 0
    var lookupMisses = 0
    var absent = 0
    var wrongOwner = 0

    var total: Int { matched + lookupMisses + absent + wrongOwner }
  }

  enum WindowIDReport: Equatable {
    case bridgeUnavailable, snapshotUnavailable, checked(WindowIDCheck)
  }

  static func checkWindowIDs(
    _ candidates: [CGWindowID?]?, expectedPID: pid_t,
    owners: () -> [CGWindowID: Set<pid_t>]?,
  ) -> WindowIDReport {
    guard let candidates else { return .bridgeUnavailable }
    guard let snapshot = owners() else { return .snapshotUnavailable }

    var result = WindowIDCheck()
    for candidate in candidates {
      guard let id = candidate, id != kCGNullWindowID else {
        result.lookupMisses += 1
        continue
      }
      guard let actual = snapshot[id] else {
        result.absent += 1
        continue
      }

      if actual == [expectedPID] {
        result.matched += 1
      } else {
        result.wrongOwner += 1
      }
    }
    return .checked(result)
  }
}

package extension HostInput {
  @MainActor
  static func smokeWindowID(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "WindowIDSmoke")
    guard arguments.count == 1, let pid = pid_t(arguments[0]), pid > 0 else {
      log.notice("Expected --smoke-window-id <pid>")
      return
    }
    guard AXIsProcessTrusted() else {
      log.notice("Accessibility trusted: false")
      return
    }

    do {
      let client = AccessibilitySystem.Client()
      let candidates = try await client.withApplication(processIdentifier: pid) { session in
        try session.debugWindowIDCandidates()
      }
      // Read CG only after AX, and do not conflate a missing snapshot with a missing row.
      let report = checkWindowIDs(candidates, expectedPID: pid) {
        guard let rows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
          return nil
        }

        return rows.reduce(into: [:]) { owners, row in
          guard let id = row[kCGWindowNumber as String] as? CGWindowID,
                let owner = row[kCGWindowOwnerPID as String] as? pid_t else { return }

          owners[id, default: []].insert(owner)
        }
      }
      switch report {
      case .bridgeUnavailable:
        log.notice("Window ID bridge unavailable")
      case .snapshotUnavailable:
        log.notice("Core Graphics window snapshot unavailable")
      case .checked(let result):
        log.notice("Window IDs: AX=\(result.total, privacy: .public) matched=\(result.matched, privacy: .public) lookup-miss=\(result.lookupMisses, privacy: .public) absent=\(result.absent, privacy: .public) wrong-owner=\(result.wrongOwner, privacy: .public)")
      }
    } catch let failure as AccessibilitySystem.Failure {
      log.error("Window ID check failed: \(failure.operation, privacy: .public) \(String(describing: failure.kind), privacy: .public)")
    } catch {
      log.error("Window ID check failed")
    }
  }
}
#endif
