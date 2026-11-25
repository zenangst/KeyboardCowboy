import AppKit
import CoreGraphics
import Foundation
import MachPortSystem

@MainActor
func say(_ message: String) {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
  let speech = Process()
  speech.executableURL = URL(filePath: "/usr/bin/say")
  speech.arguments = [message]
  if (try? speech.run()) != nil {
    // Keep installed taps responsive during spoken prompts.
    driveRunLoop(seconds: 30) { !speech.isRunning }
  }
}

@MainActor
func driveRunLoop(seconds: Int, until done: () -> Bool = { false }) {
  let deadline = ContinuousClock.now + .seconds(seconds)
  while ContinuousClock.now < deadline && !done() {
    if CFRunLoopRunInMode(.defaultMode, 0.05, false) == .finished {
      Thread.sleep(forTimeInterval: 0.05)
    }
  }
}

private struct Events: Equatable {
  var keyDown = 0
  var keyUp = 0
  var shiftDown = 0
  var shiftUp = 0

  var hasKeyPair: Bool { keyDown > 0 && keyUp > 0 }
  var hasShiftPair: Bool { shiftDown > 0 && shiftUp > 0 }
  var hasExactlyOneKeyPair: Bool { keyDown == 1 && keyUp == 1 }

  mutating func record(_ event: MachPortSystem.InterceptedEvent) {
    switch (event.type, event.keyCode) {
    case (.keyDown, 0) where !event.isRepeat: keyDown += 1
    case (.keyUp, 0): keyUp += 1
    case (.flagsChanged, 56):
      if event.event.flags.contains(.maskShift) { shiftDown += 1 } else { shiftUp += 1 }
    default: break
    }
  }
}

@MainActor
private func monitorRevocation() throws -> Int32 {
  guard Bundle.main.bundleIdentifier == "org.keyboardcowboy.event-tap-permission-probe" else {
    say("Run revocation mode using the dedicated Cowboy Event Tap Probe app.")
    return 2
  }
  guard CGPreflightListenEventAccess() else {
    say("Input Monitoring is denied. No tap was started.")
    return 2
  }

  var events = Events()
  var disruptions: [MachPortSystem.EventTap.Disruption] = []
  let tap = MachPortSystem.EventTap(syntheticSignature: Int64.random(in: 1 ..< Int64.max)) { event in
    events.record(event)
    return .passThrough
  } onDisruption: { disruptions.append($0) }
  defer { tap.stop() }
  try tap.start()

  say("Probe ready. Focus TextEdit, tap and release A once, and wait for the next cue.")
  driveRunLoop(seconds: 25) { events.hasKeyPair }
  guard events.hasKeyPair else {
    say("Inconclusive. No physical key pair arrived before changing permission.")
    return 2
  }
  driveRunLoop(seconds: 3)
  say("Turn off only Cowboy Event Tap Probe under Input Monitoring. If asked to quit, choose Later. Do not change Accessibility.")
  driveRunLoop(seconds: 35) { !CGPreflightListenEventAccess() }
  let before = events
  say("Return to TextEdit, tap and release A once, and confirm a character appeared. Leave permission off.")
  driveRunLoop(seconds: 20)
  let listening = CGPreflightListenEventAccess()
  let posting = CGPreflightPostEventAccess()
  let delivered = events.keyDown > before.keyDown && events.keyUp > before.keyUp
  let enabled = tap.isEnabled
  tap.stop()
  tap.stop()
  let stopped = !tap.isRunning
  print("Input Monitoring: \(listening); posting: \(posting); tap enabled before stop: \(enabled)")
  print("Key pair delivered after revoke cue: \(delivered); disruptions: \(disruptions); stop completed twice: \(stopped)")
  say("Probe finished. Leave Input Monitoring off for the fresh launch check.")
  return stopped ? 0 : 1
}

@MainActor
private func run(pid: Int32, timeout: Bool) throws -> Int32 {
  let signature = Int64.random(in: 1 ..< Int64.max)
  var routedPhysical = Events()
  var routedTagged = Events()
  var witnessedPhysical = Events()
  var witnessedTagged = Events()
  var disruptions: [MachPortSystem.EventTap.Disruption] = []
  var witnessDisrupted = false
  var stallNext = false
  let tap = MachPortSystem.EventTap(syntheticSignature: signature) { event in
    if event.event.getIntegerValueField(.eventSourceUserData) == signature {
      routedTagged.record(event)
    } else {
      routedPhysical.record(event)
      if stallNext, event.type == .keyDown, event.keyCode == 0, !event.isRepeat {
        stallNext = false
        Thread.sleep(forTimeInterval: 2)
      }
    }
    return .passThrough
  } onDisruption: { disruptions.append($0) }
  // A differently tagged downstream tap proves the posted events were actually
  // delivered. Silence in the primary tap alone cannot prove that they bypassed it.
  let witness = MachPortSystem.EventTap(
    configuration: .init(placement: .tailAppendEventTap), syntheticSignature: signature + 1,
  ) { event in
    if event.event.getIntegerValueField(.eventSourceUserData) == signature {
      witnessedTagged.record(event)
    } else {
      witnessedPhysical.record(event)
    }
    return .passThrough
  } onDisruption: { _ in witnessDisrupted = true }
  defer {
    tap.stop()
    witness.stop()
  }
  try tap.start()
  try witness.start()

  if timeout {
    stallNext = true
    say("Timeout probe ready. Focus TextEdit. Tap and release A once, then wait for the next cue.")
    driveRunLoop(seconds: 25) { !disruptions.isEmpty || witnessDisrupted }
    guard !stallNext, !witnessDisrupted, disruptions == [.timeout] else {
      say("Inconclusive. The primary tap did not report a timeout, or the witness tap was disrupted.")
      return 2
    }
    driveRunLoop(seconds: 2)
    guard tap.isRunning, !tap.isEnabled else {
      say("The probe failed. The primary tap did not stay installed and disabled.")
      return 1
    }
    let disabledBaseline = routedPhysical
    witnessedPhysical = Events()
    say("Timeout confirmed. While the tap is disabled, tap and release A once more.")
    driveRunLoop(seconds: 25) { witnessedPhysical.hasKeyPair || witnessDisrupted }
    guard !witnessDisrupted, witnessedPhysical.hasKeyPair else {
      say("Inconclusive. The witness did not see the physical key pair.")
      return 2
    }
    let disabledQuiet = routedPhysical == disabledBaseline && !tap.isEnabled

    try tap.reload()
    guard tap.isEnabled else {
      say("The probe failed. Reload did not enable the tap.")
      return 1
    }
    routedPhysical = Events()
    witnessedPhysical = Events()
    driveRunLoop(seconds: 2)
    say("Tap reloaded. Tap and release A once, then wait.")
    driveRunLoop(seconds: 25) { witnessedPhysical.hasKeyPair || witnessDisrupted }
    driveRunLoop(seconds: 1)
    guard !witnessDisrupted, witnessedPhysical.hasExactlyOneKeyPair else {
      say("Inconclusive. The witness did not confirm exactly one physical key pair after reload.")
      return 2
    }
    let recovered = routedPhysical.hasExactlyOneKeyPair && disruptions == [.timeout]
    tap.stop()
    let stoppedBaseline = routedPhysical
    witnessedPhysical = Events()
    driveRunLoop(seconds: 2)
    say("Primary tap stopped. Tap and release A one last time.")
    driveRunLoop(seconds: 25) { witnessedPhysical.hasKeyPair || witnessDisrupted }
    guard !witnessDisrupted, witnessedPhysical.hasKeyPair else {
      say("Inconclusive. The witness did not see the final physical key pair.")
      return 2
    }
    let stoppedQuiet = routedPhysical == stoppedBaseline
    let passed = disabledQuiet && recovered && stoppedQuiet
    print("Timeout: true; disabled silence: \(disabledQuiet); reload delivery: \(recovered); stopped silence: \(stoppedQuiet)")
    say(passed ? "The timeout and recovery probe passed." : "The timeout and recovery probe did not pass.")
    return passed ? 0 : 1
  }

  func disrupted() -> Bool { !disruptions.isEmpty || witnessDisrupted }
  say("Tap ready. Focus the blank TextEdit document. Tap and release left Shift, then tap and release the A key without modifiers.")
  driveRunLoop(seconds: 25) { (routedPhysical.hasKeyPair && routedPhysical.hasShiftPair) || disrupted() }
  guard !disrupted(), routedPhysical.hasKeyPair, routedPhysical.hasShiftPair else {
    say("Inconclusive. The primary tap did not observe both physical pairs, or a tap was disrupted.")
    return 2
  }
  driveRunLoop(seconds: 1)

  let modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]
  guard !disrupted(), NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
        CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty else {
    say("Inconclusive. TextEdit must be frontmost and all modifiers must be released before posting.")
    return 2
  }
  let poster = try tap.makeKeyboardEventPoster()
  let beforePosting = routedPhysical
  try poster.post(keyCode: 0, action: .down)
  try poster.post(keyCode: 0, action: .up)
  driveRunLoop(seconds: 3)
  guard !disrupted(), witnessedTagged.hasKeyPair else {
    say("Inconclusive. The downstream tap did not confirm delivery of both tagged events.")
    return 2
  }
  let bypassed = routedTagged == Events() && routedPhysical == beforePosting
  tap.stop()
  let beforeStoppedPhase = routedPhysical
  driveRunLoop(seconds: 3)

  witnessedPhysical = Events()
  say("Primary tap stopped. With TextEdit focused, tap and release the A key once more.")
  driveRunLoop(seconds: 25) { witnessedPhysical.hasKeyPair || disrupted() }
  guard !disrupted(), witnessedPhysical.hasKeyPair else {
    say("Inconclusive. The downstream tap did not see the final physical key pair.")
    return 2
  }
  let stopped = routedPhysical == beforeStoppedPhase
  FileHandle.standardError.write(Data("Physical delivery: true; tagged bypass: \(bypassed); stopped silence: \(stopped)\n".utf8))
  say(bypassed && stopped ? "The Mach port probe passed." : "The Mach port probe did not pass.")
  return bypassed && stopped ? 0 : 1
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments == ["--revoke-posting"] {
  guard Bundle.main.bundleIdentifier == "org.keyboardcowboy.event-tap-permission-probe",
        !CGPreflightListenEventAccess(), CGPreflightPostEventAccess() else {
    say("Use the dedicated probe app with Input Monitoring off and Accessibility on.")
    exit(2)
  }
  say("Probe ready. Turn off Accessibility for Cowboy Event Tap Probe only. Leave Input Monitoring off.")
  driveRunLoop(seconds: 45) { !CGPreflightPostEventAccess() }
  let listening = CGPreflightListenEventAccess()
  let posting = CGPreflightPostEventAccess()
  print("Running after revoke cue: Input Monitoring: \(listening); posting: \(posting); no tap or events posted.")
  say("Running process check complete. Leave both permissions off for the fresh launch check.")
  exit(listening ? 2 : 0)
}
if arguments == ["--permissions"] {
  let listening = CGPreflightListenEventAccess()
  let posting = CGPreflightPostEventAccess()
  print("Input Monitoring: \(listening); posting: \(posting); no tap started.")
  say("Input Monitoring is \(listening ? "allowed" : "denied"). Posting is \(posting ? "allowed" : "denied"). No tap was started.")
  exit(0)
}

let timeout = arguments.dropFirst().elementsEqual(["--timeout"])
let revocation = arguments.dropFirst().elementsEqual(["--revoke-input-monitoring"])
guard arguments.count == 1 || timeout || revocation,
      let first = arguments.first, let pid = Int32(first),
      let app = NSRunningApplication(processIdentifier: pid), app.bundleIdentifier == "com.apple.TextEdit" else {
  FileHandle.standardError.write(Data("Usage: EventTapProbe --permissions | --revoke-posting | TEXTEDIT_PID [--timeout|--revoke-input-monitoring]\n".utf8))
  exit(2)
}
guard CGPreflightListenEventAccess(), CGPreflightPostEventAccess() else {
  say("The active tap probe needs Input Monitoring and Accessibility permissions. No tap was started.")
  exit(2)
}
do {
  exit(try revocation ? monitorRevocation() : run(pid: pid, timeout: timeout))
} catch {
  FileHandle.standardError.write(Data("Probe error: \(error)\n".utf8))
  say("The Mach port probe could not complete.")
  exit(2)
}
