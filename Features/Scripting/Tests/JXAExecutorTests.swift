import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

@Test func testJXAExecutor() throws {
  let executor = JXA.Executor(.testing)
  let (output, processes) = try executor.execute("hello world!")

  #expect(processes.count == 1)
}
