import Carbon
import Foundation
@testable import HostInput
import KeyCodeSystem
import Testing

@MainActor
@Test func keyboardLayoutSessionReloadsOnlyForInputSourceChangesOrExplicitRefresh() throws {
  let us = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.US")
  let french = try KeyCodeSystem.Layout(inputSourceID: "com.apple.keylayout.French")
  let center = NotificationCenter()
  var next: KeyCodeSystem.Layout? = us
  var loads = 0
  let session = HostInput.KeyboardLayoutSession(center: center) {
    loads += 1
    guard let next else { throw KeyCodeSystem.LookupError.layoutUnavailable }
    return next
  }

  #expect(loads == 1)
  #expect(session.layout?.keyCode(for: "a") == kVK_ANSI_A)
  next = french
  center.post(name: Notification.Name("unrelated"), object: nil)
  #expect(session.layout?.keyCode(for: "a") == kVK_ANSI_A)
  #expect(loads == 1)

  center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
  #expect(session.layout?.keyCode(for: "a") == kVK_ANSI_Q)
  #expect(loads == 2)

  next = nil
  center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
  #expect(session.layout == nil)
  next = us
  session.refresh()
  #expect(session.layout?.keyCode(for: "a") == kVK_ANSI_A)
  #expect(loads == 4)
}

@MainActor
@Test func releasingKeyboardLayoutSessionStopsObserving() {
  let center = NotificationCenter()
  var loads = 0
  var session: HostInput.KeyboardLayoutSession? = .init(center: center) {
    loads += 1
    throw KeyCodeSystem.LookupError.layoutUnavailable
  }
  weak var weakSession = session
  #expect(loads == 1)
  session = nil
  #expect(weakSession == nil)
  center.post(name: HostInput.KeyboardLayoutSession.sourceChanged, object: nil)
  #expect(loads == 1)
}
