import RuntimeEnvironment
import Testing

@Test func runtimeModes() {
  let production: RuntimeEnvironment.Mode = .production
  if case .production = production {} else {
    Issue.record("Expected production mode")
  }

  #if DEBUG
  let testing: RuntimeEnvironment.Mode = .testing
  if case .testing = testing {} else {
    Issue.record("Expected testing mode")
  }
  #endif
}
