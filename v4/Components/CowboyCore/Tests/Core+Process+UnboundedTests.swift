import Foundation
import Testing
import CowboyCore

@Test func unboundedCaptureDrainsBothStreamsAndReportsStatus() throws {
  let process = Core.Process(.production, launchStyle: .headless("test"))
  process.executableURL = URL(filePath: "/bin/sh")
  process.arguments = ["-c", "head -c 1048576 /dev/zero & head -c 1048576 /dev/zero >&2 & wait; exit 7"]
  process.standardOutput = Core.Pipe(.production)
  process.standardError = Core.Pipe(.production)
  let output = try process.runAndCaptureOutputUnbounded()
  #expect(output.stdout?.count == 1048576)
  #expect(output.stderr?.count == 1048576)
  #expect(process.terminationStatus == 7)
}
