import Foundation
@testable import OpenFeature
import Testing

#if DEBUG
  @Test func runningApplicationBoundaryUsesInjectedLookupAndActivation() {
    let mock = Open.System.Mock(
      firstRunningProcess: { $0 == "com.apple.Safari" ? 123 : nil },
      activate: { $0 == 123 }
    )
    let system = Open.System(environment: .testing)
    Open.System.Testing.$mock.withValue(mock) {
      #expect(system.firstRunningProcess(bundleIdentifier: "com.apple.Safari") == 123)
      #expect(system.firstRunningProcess(bundleIdentifier: "other") == nil)
      #expect(system.activate(processIdentifier: 123))
      #expect(!system.activate(processIdentifier: 456))
    }
  }
#endif
