import AccessibilitySystem
import AppKit
import ApplicationServices
import Foundation

func report(_ message: String) {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
}

let arguments = Array(CommandLine.arguments.dropFirst())
let destructionOnly = arguments.dropFirst().elementsEqual(["--destruction"])
let terminationOnly = arguments.dropFirst().elementsEqual(["--termination"])
let revocationOnly = arguments.dropFirst().elementsEqual(["--revocation"])
guard arguments.count == 1 || destructionOnly || terminationOnly || revocationOnly,
      let rawPID = arguments.first, let pid = Int32(rawPID), pid > 0 else {
  report("Usage: WindowObservationProbe PID [--destruction|--termination|--revocation]")
  exit(2)
}

func say(_ message: String) {
  report(message)
  let speech = Process()
  speech.executableURL = URL(filePath: "/usr/bin/say")
  speech.arguments = [message]
  if (try? speech.run()) != nil { speech.waitUntilExit() }
}

func finish(_ status: Int32) -> Never {
  switch status {
  case 0: say("The window observation probe passed.")
  case 1: say("The window observation probe did not pass.")
  default: say("The window observation probe was inconclusive.")
  }
  exit(status)
}

guard AXIsProcessTrusted() else {
  say("The window observation probe needs Accessibility permission.")
  exit(2)
}

let app = AXUIElementCreateApplication(pid)
@MainActor
func windowCount(_ phase: String) -> Int {
  var count: CFIndex = 0
  let status = AXUIElementGetAttributeValueCount(app, kAXWindowsAttribute as CFString, &count)
  report("AX window count \(phase): \(count) (status \(status.rawValue))")
  guard status == .success else { finish(2) }

  return count
}

@MainActor
func driveRunLoop(seconds: Int, until done: () -> Bool = { false }) {
  let deadline = ContinuousClock.now + .seconds(seconds)
  while ContinuousClock.now < deadline && !done() {
    if CFRunLoopRunInMode(.defaultMode, 0.1, false) == .finished {
      Thread.sleep(forTimeInterval: 0.05)
    }
  }
}

let observer = AccessibilitySystem.WindowObservation()
@MainActor
func start(_ pid: Int32, receive: @escaping @MainActor (AccessibilitySystem.WindowEvent) -> Void) {
  do {
    try observer.start(processIdentifier: pid, receive: receive)
  } catch {
    report("Observer registration failed: \(error)")
    finish(2)
  }
}

if revocationOnly {
  guard Bundle.main.bundleIdentifier == "org.keyboardcowboy.ax-revocation-probe",
        let target = NSRunningApplication(processIdentifier: pid),
        target.bundleIdentifier == "com.apple.TextEdit" else {
    report("Use the dedicated revocation app bundle and a running TextEdit PID.")
    finish(2)
  }

  _ = windowCount("before revocation")
  var events = 0
  start(pid) { _ in events += 1 }
  say("Probe ready. In Accessibility settings, turn off only Cowboy AX Revocation Probe. Leave TextEdit open.")
  driveRunLoop(seconds: 60) { !AXIsProcessTrusted() || target.isTerminated }
  let trustLost = !AXIsProcessTrusted()
  var count: CFIndex = 0
  let status = AXUIElementGetAttributeValueCount(app, kAXWindowsAttribute as CFString, &count)
  observer.stop()
  observer.stop()
  let stoppedCount = events
  driveRunLoop(seconds: 2)
  let passed = trustLost && status == .apiDisabled && !target.isTerminated && events == stoppedCount
  report("Trust lost: \(trustLost); AX read status: \(status.rawValue); stop completed twice; callback quiet: \(events == stoppedCount)")
  finish(passed ? 0 : 2)
}

if terminationOnly {
  let bundleID = "com.apple.TextEdit"
  guard let original = NSRunningApplication(processIdentifier: pid), original.bundleIdentifier == bundleID else {
    report("Expected a running TextEdit process.")
    finish(2)
  }

  var originalEvents = 0
  start(pid) { _ in originalEvents += 1 }
  say("Quit TextEdit now with Command Q. Wait for the reopen cue.")
  driveRunLoop(seconds: 30) { original.isTerminated }
  guard original.isTerminated else {
    report("Original TextEdit did not exit.")
    finish(2)
  }

  observer.stop()
  observer.stop()
  let stoppedCount = originalEvents
  report("Original PID \(pid) terminated; stop completed twice.")
  driveRunLoop(seconds: 3)
  say("Reopen TextEdit and let its original window restore. Do not open another window yet.")
  var replacement: NSRunningApplication?
  var replacementApp: AXUIElement?
  var before: CFIndex = 0
  driveRunLoop(seconds: 45) {
    guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first(where: {
      $0.processIdentifier != pid && !$0.isTerminated && $0.isFinishedLaunching
    }) else { return false }

    let candidate = AXUIElementCreateApplication(running.processIdentifier)
    var count: CFIndex = 0
    guard AXUIElementGetAttributeValueCount(candidate, kAXWindowsAttribute as CFString, &count) == .success,
          count > 0 else { return false }

    before = count
    replacement = running
    replacementApp = candidate
    return true
  }
  guard let replacement, let replacementApp else {
    report("No relaunched TextEdit with a new PID and a readable AX window.")
    finish(2)
  }

  // Give the restored window and the spoken reopen cue time to settle.
  driveRunLoop(seconds: 5)
  let baselineStatus = AXUIElementGetAttributeValueCount(
    replacementApp, kAXWindowsAttribute as CFString, &before)
  guard baselineStatus == .success, before > 0 else {
    report("Inconclusive: the restored window is no longer readable.")
    finish(2)
  }

  var events: [AccessibilitySystem.WindowEvent] = []
  start(replacement.processIdentifier) { event in
    events.append(event)
    report("Replacement callback: \(event)")
  }
  report("Observer restarted: TextEdit PID \(replacement.processIdentifier), \(before) AX windows.")
  say("Observer restarted. Open a separate TextEdit window, switch focus to the original window, and leave both windows open.")
  driveRunLoop(seconds: 30)
  observer.stop()
  var after: CFIndex = 0
  let status = AXUIElementGetAttributeValueCount(replacementApp, kAXWindowsAttribute as CFString, &after)
  report("Replacement AX window count: \(before) to \(after) (status \(status.rawValue)).")
  guard status == .success, after > before else {
    report("Inconclusive: no additional AX window was verified.")
    finish(2)
  }

  let resumed = events.contains(.created) && events.contains(.focusChanged)
  let originalQuiet = originalEvents == stoppedCount
  report("Replacement delivery: \(resumed); original callback stayed silent: \(originalQuiet)")
  finish(resumed && originalQuiet ? 0 : 1)
}

if destructionOnly {
  let before = windowCount("before close")
  guard before >= 2 else {
    report("Open at least two separate disposable TextEdit windows before running.")
    finish(2)
  }

  var events: [AccessibilitySystem.WindowEvent] = []
  start(pid) { event in
    events.append(event)
    report("Callback: \(event)")
  }
  say("Close one disposable TextEdit window now. Leave the other windows open.")
  driveRunLoop(seconds: 25)
  observer.stop()
  let after = windowCount("after close")
  let closedOne = after == before - 1
  let receivedDestruction = events.contains(.elementDestroyed)
  report("Exactly one window closed: \(closedOne); app-level destruction delivered: \(receivedDestruction)")
  finish(closedOne ? (receivedDestruction ? 0 : 1) : 2)
}

var first: [AccessibilitySystem.WindowEvent] = []
var second: [AccessibilitySystem.WindowEvent] = []
let before = windowCount("before")
start(pid) { event in
  first.append(event)
  report("Initial callback: \(event)")
}

say("Observer ready. Open a separate TextEdit window, switch focus to another window, and leave the new window open.")
driveRunLoop(seconds: 25)
observer.stop()

let beforeStop = windowCount("at stop")
let firstCount = first.count
driveRunLoop(seconds: 3)
say("Observer stopped. Open another separate TextEdit window and leave it open.")
driveRunLoop(seconds: 20)
let afterStop = windowCount("after stopped phase")
let quietWhileStopped = first.count == firstCount

driveRunLoop(seconds: 3)
start(pid) { event in
  second.append(event)
  report("Restarted callback: \(event)")
}

say("Observer restarted. Open one more separate TextEdit window, switch focus, and leave all windows open.")
driveRunLoop(seconds: 25)
observer.stop()
let afterRestart = windowCount("after restart")

let initialOK = beforeStop > before && first.contains(.created) && first.contains(.focusChanged)
let stoppedOK = quietWhileStopped && afterStop > beforeStop
let restartedOK = afterRestart > afterStop && second.contains(.created)
  && second.contains(.focusChanged) && first.count == firstCount
report("Initial delivery: \(initialOK); stopped silence: \(stoppedOK); restart delivery: \(restartedOK)")
let actionsVerified = beforeStop > before && afterStop > beforeStop && afterRestart > afterStop
finish(actionsVerified ? (initialOK && stoppedOK && restartedOK ? 0 : 1) : 2)
