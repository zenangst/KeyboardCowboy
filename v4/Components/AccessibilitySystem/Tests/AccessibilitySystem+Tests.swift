@testable import AccessibilitySystem
import ApplicationServices
import Foundation
import Testing

private typealias AX = AccessibilitySystem // swiftlint:disable:this type_name

// A fresh fixture is constructed on the worker for every transaction.
private final class Fixture: AX.Transport {
  let app = AX.Handle()
  let first = AX.Handle()
  let second = AX.Handle()
  let nested = AX.Handle()
  var timeoutHandles: Set<AX.Handle> = []
  var failWindows = false
  var failTimeout = false
  var failRaise = false
  var raisedHandles: [AX.Handle] = []
  var pressedHandles: [AX.Handle] = []
  var mainHandle: AX.Handle?
  var selectedText = ""
  var missingSelection = false
  var missingFirstURL = false
  var stringURL = false
  var cycle = false
  var malformedRole = false
  var onRead: (() -> Void)?
  var hitPoint: CGPoint?
  var selectBothDirectChildren = false
  var secondHasReadableChildren = false

  func application(_ pid: Int32) -> AX.Handle { app }
  var focusOnApp = false
  func focusedElement() throws -> AX.Handle { focusOnApp ? app : first }
  func element(at point: CGPoint) throws -> AX.Handle {
    guard point == hitPoint else {
      throw AX.Failure(.noValue, operation: "elementAtPosition", rawAXStatus: AXError.noValue.rawValue)
    }
    return first
  }

  func setTimeout(_ seconds: Float, on handle: AX.Handle) throws {
    #expect(seconds > 0)
    if failTimeout {
      throw AX.Failure(
        .cannotComplete,
        operation: "setMessagingTimeout",
        rawAXStatus: -25204,
      )
    }
    timeoutHandles.insert(handle)
  }

  func read(_ name: String, from handle: AX.Handle) throws -> AX.ReadValue {
    onRead?()
    #expect(timeoutHandles.contains(handle))
    if name == "AXFocused" { return .bool(handle == second) }
    if name == "AXSelected" {
      return .bool(handle == first || handle == nested || (selectBothDirectChildren && handle == second))
    }
    if name == "AXFocusedWindow", handle == app { return .element(second) }
    if name == "AXParent", handle == first { return .element(second) }
    if name == "AXPosition" { return .point(CGPoint(x: -140, y: 40)) }
    if name == "AXSize" { return .size(CGSize(width: 30, height: 10)) }
    if name == "AXSelectedText" {
      #expect(handle == first)
      if missingSelection { throw AX.Failure(.noValue, operation: name) }
      return .string(selectedText)
    }
    if name == "AXWindows" {
      if failWindows {
        throw AX.Failure(.cannotComplete, operation: name, rawAXStatus: -25204)
      }
      return .elements([first, second])
    }

    if name == "AXChildren" {
      if handle == app { return .elements([first, second]) }
      if handle == first { return .elements([nested]) }
      if handle == second, secondHasReadableChildren { return .elements([]) }
      if cycle { return .elements([app]) }
      throw AX.Failure(.attributeUnsupported, operation: name)
    }

    if name == "AXRole" {
      if malformedRole { return .malformed }
      return .string(handle == app ? "AXApplication" : "AXWebArea")
    }

    if name == "AXURL" {
      if handle == first && missingFirstURL { throw AX.Failure(.noValue, operation: name) }
      if stringURL { return .string("https://example.com") }
      let path = handle == first ? "first" : handle == second ? "second" : "nested"
      return .url(URL(string: "https://example.com/\(path)")!)
    }

    throw AX.Failure(.attributeUnsupported, operation: name)
  }

  func perform(_ action: AX.Action, on handle: AX.Handle) throws {
    #expect(timeoutHandles.contains(handle))
    switch action {
    case .raise:
      if failRaise {
        throw AX.Failure(.actionUnsupported, operation: kAXRaiseAction,
                         rawAXStatus: AXError.actionUnsupported.rawValue)
      }
      raisedHandles.append(handle)
    case .press:
      pressedHandles.append(handle)
    }
  }

  func write(_ name: String, value: Bool, to handle: AX.Handle) throws {
    #expect(timeoutHandles.contains(handle))
    #expect(name == "AXMain")
    mainHandle = value ? handle : nil
  }

  func write(_ name: String, value: String, to handle: AX.Handle) throws {
    #expect(timeoutHandles.contains(handle))
    #expect(handle == first)
    #expect(name == "AXSelectedText")
    selectedText = value
  }
}

@Test func focusedChildSearchPreservesOrderAndDoesNotDescend() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.focusOnApp = true
    return fixture
  })
  try await client.withFocusedElement { group in
    let first = try group.firstChild {
      try $0.read(.focused) || $0.read(.selected)
    }
    let url = try first?.read(.url)
    #expect(url?.lastPathComponent == "first")
    let nested = try group.firstChild { try $0.read(.url).lastPathComponent == "nested" }
    #expect(nested == nil)
  }
}

@Test func readableChildrenSearchSkipsUnreadableNodeAndKeepsPreorder() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.focusOnApp = true
    fixture.secondHasReadableChildren = true
    return fixture
  })
  try await client.withFocusedElement { root in
    var visited: [String] = []
    let match = try root.firstInSubtreeWithReadableChildren { node in
      visited.append(try node.read(.role) == .webArea ? node.read(.url).lastPathComponent : "root")
      return try node.read(.focused)
    }
    #expect(visited == ["root", "first", "second"])
    #expect(try match?.read(.url).lastPathComponent == "second")
  }
}

@Test func readableChildrenSearchReportsBudgetExhaustion() async {
  let client = AX.Client(makeTransport: { Fixture() })
  await #expect(throws: AX.Failure.self) {
    try await client.withFocusedElement { root in
      try root.firstInSubtreeWithReadableChildren(budget: .init(maximumNodes: 1)) { _ in false } != nil
    }
  }
}

@Test func selectedDirectChildSearchStopsAtFirstMatch() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.focusOnApp = true
    fixture.selectBothDirectChildren = true
    return fixture
  })
  try await client.withFocusedElement { container in
    var inspected: [String] = []
    let child = try container.firstChild {
      inspected.append(try $0.read(.url).lastPathComponent)
      return try $0.read(.selected)
    }
    #expect(try child?.read(.url).lastPathComponent == "first")
    #expect(inspected == ["first"])
  }
}

@Test func pressUsesScopedElementHandle() throws {
  let queue = DispatchQueue(label: "AccessibilitySystemTests.press")
  try queue.sync {
    let fixture = Fixture()
    let session = try AX.Session(pid: 42, transport: fixture, timeout: 0.25,
                                 queue: queue, request: AX.Request())
    defer { session.invalidate() }
    let target = try session.focusedElement()
    try session.perform(.press, on: target)
    #expect(fixture.pressedHandles == [fixture.first])
  }
}

@Test func focusedElementCanReadEmptySelectionAndWriteReplacement() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  try await client.withFocusedElement { focused in
    #expect(try focused.read(.selectedText).isEmpty)
    try focused.write(.selectedText, value: "replacement")
    #expect(try focused.read(.selectedText) == "replacement")
  }
}

@Test func focusAndWindowRelationsShareOneSession() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  try await client.withApplication(processIdentifier: 42) { session in
    let focus = try session.focusedElement()
    let window = try #require(try session.focusedWindow())
    #expect(try session.parent(of: focus) == window)
    #expect(try session.parent(of: window) == nil)
  }
}

@Test func hitTestUsesGlobalCoordinatesAndReadsHitElement() async throws {
  let point = CGPoint(x: -120.5, y: 44.25)
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.hitPoint = point
    return fixture
  })

  let (role, frame) = try await client.withElement(at: point) { (try $0.read(.role), try $0.frame()) }
  #expect(role == .webArea)
  #expect(frame == CGRect(x: -140, y: 40, width: 30, height: 10))
  #expect(frame.contains(point))
}

@Test func nativeDecoderValidatesGeometryWithoutRemoteCalls() throws {
  var position = CGPoint(x: -140, y: 40)
  var size = CGSize(width: 30, height: 10)
  var range = CFRange(location: 0, length: 1)

  let axPosition = try #require(AXValueCreate(.cgPoint, &position))
  let axSize = try #require(AXValueCreate(.cgSize, &size))
  let axRange = try #require(AXValueCreate(.cfRange, &range))
  let positionAttribute = AX.Attribute<CGPoint>.position
  let sizeAttribute = AX.Attribute<CGSize>.size
  let decodedPosition = try AX.NativeTransport.decode(axPosition, operation: "AXPosition")
  #expect(try positionAttribute.decode(decodedPosition) == position)
  #expect(try sizeAttribute.decode(AX.NativeTransport.decode(axSize, operation: "AXSize")) == size)
  #expect(throws: AX.Failure.self) { try sizeAttribute.decode(decodedPosition) }
  #expect(throws: AX.Failure.self) { try AX.NativeTransport.decode(axRange, operation: "AXPosition") }
}

@Test func hitTestPreservesNoValueAndDoesNotCallOperation() async {
  let client = AX.Client(makeTransport: { Fixture() })
  do {
    try await client.withElement(at: .zero) { _ in Issue.record("Unexpected hit") }
    Issue.record("Expected hit-test failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .noValue)
    #expect(failure.operation == "elementAtPosition")
    #expect(failure.rawAXStatus == AXError.noValue.rawValue)
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}

@Test func nativeHitTestRejectsInvalidCoordinatesBeforeAXCall() {
  #expect(throws: AX.Failure.self) {
    try AX.NativeTransport().element(at: CGPoint(x: CGFloat.infinity, y: 0))
  }
}

@Test func missingSelectionIsNotAnEmptySelection() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.missingSelection = true
    return fixture
  })
  do {
    _ = try await client.withFocusedElement { try $0.read(.selectedText) }
    Issue.record("Expected no selected text value")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .noValue)
    #expect(failure.operation == "AXSelectedText")
  }
}

@Test func orderedWindowsAndTypedReads() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  let urls = try await client.withApplication(processIdentifier: 42) { session in
    try session.windows().map { try session.read(.url, of: $0).absoluteString }
  }
  #expect(urls == ["https://example.com/first", "https://example.com/second"])
}

@Test func typedURLReadRejectsString() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.stringURL = true
    return fixture
  })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      try session.read(.url, of: session.application)
    }
    Issue.record("Expected URL read to reject a string")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .malformedValue)
    #expect(failure.operation == "AXURL")
  }
}

@Test func rootInclusionAndPreorder() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  let values = try await client.withApplication(processIdentifier: 42) { session in
    let root = try session.windows()[0]
    let included = try session.firstValue(of: .url, atRole: .webArea, under: root,
                                          includingRoot: true, missingValue: .skipNoValueOrUnsupported)
    let excluded = try session.firstValue(of: .url, atRole: .webArea, under: root,
                                          includingRoot: false, missingValue: .skipNoValueOrUnsupported)
    return [included?.lastPathComponent, excluded?.lastPathComponent]
  }
  #expect(values == ["first", "nested"])
}

@Test func missingValuePrunesMatchedRoleButNotSiblings() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.missingFirstURL = true
    return fixture
  })
  let result = try await client.withApplication(processIdentifier: 42) { session in
    try session.firstValue(of: .url, atRole: .webArea, under: session.application,
                           includingRoot: true, missingValue: .skipNoValueOrUnsupported)
  }
  #expect(result?.lastPathComponent == "second")
}

@Test func failedEnumerationPreservesStatus() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.failWindows = true
    return fixture
  })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { try $0.windows().count }
    Issue.record("Expected enumeration failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .cannotComplete)
    #expect(failure.rawAXStatus == -25204)
  }
}

@Test func raiseUsesWindowHandleAndChecksCancellationBeforeDispatch() throws {
  let queue = DispatchQueue(label: "AccessibilitySystemTests.raise")
  try queue.sync {
    let fixture = Fixture()
    let request = AX.Request()
    let session = try AX.Session(pid: 42, transport: fixture, timeout: 0.25,
                                 queue: queue, request: request)
    defer { session.invalidate() }
    let window = try #require(session.windows().first)

    try session.write(.main, value: true, to: window)
    #expect(fixture.mainHandle == fixture.first)
    try session.perform(.raise, on: window)
    #expect(fixture.raisedHandles == [fixture.first])

    request.cancel()
    #expect(throws: CancellationError.self) { try session.write(.main, value: false, to: window) }
    #expect(fixture.mainHandle == fixture.first)
    #expect(throws: CancellationError.self) { try session.perform(.raise, on: window) }
    #expect(fixture.raisedHandles == [fixture.first])
  }
}

@Test func failedRaisePreservesStatus() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.failRaise = true
    return fixture
  })
  do {
    try await client.withApplication(processIdentifier: 42) { session in
      let window = try #require(session.windows().first)
      try session.perform(.raise, on: window)
    }
    Issue.record("Expected raise failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .actionUnsupported)
    #expect(failure.operation == kAXRaiseAction)
    #expect(failure.rawAXStatus == AXError.actionUnsupported.rawValue)
  }
}

@Test func timeoutSetupFailureIsNotIgnored() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.failTimeout = true
    return fixture
  })
  await #expect(throws: AX.Failure.self) {
    try await client.withApplication(processIdentifier: 42) { _ in true }
  }
}

@Test func malformedValuesAreNotMissing() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.malformedRole = true
    return fixture
  })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      try session.firstValue(of: .url, atRole: .webArea, under: session.application,
                             includingRoot: true, missingValue: .skipNoValueOrUnsupported)
    }
    Issue.record("Expected malformed value failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .malformedValue)
  }
}

@Test func cyclesTerminateAndNoMatchIsNil() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.cycle = true
    return fixture
  })
  let result = try await client.withApplication(processIdentifier: 42) { session in
    try session.firstValue(of: .url, atRole: .button, under: session.application,
                           includingRoot: true, missingValue: .skipNoValueOrUnsupported)
  }
  #expect(result == nil)
}

@Test func budgetExhaustionIsNotNoMatch() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      try session.firstValue(of: .url, atRole: .button, under: session.application,
                             includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                             budget: .init(maximumNodes: 1))
    }
    Issue.record("Expected budget failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .traversalLimitReached)
  }
}

@Test func traversalBudgetsDoNotSetTimeoutsOnUnvisitedChildren() throws {
  let queue = DispatchQueue(label: "AccessibilitySystemTests.traversal")
  try queue.sync {
    let fixture = Fixture()
    let session = try AX.Session(pid: 42, transport: fixture, timeout: 0.25,
                                 queue: queue, request: AX.Request())
    defer { session.invalidate() }

    for budget in [AX.TraversalBudget(maximumNodes: 1), .init(maximumDepth: 0)] {
      #expect(throws: AX.Failure.self) {
        try session.firstValue(of: .url, atRole: .webArea, under: session.application,
                               includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                               budget: budget)
      }
      #expect(fixture.timeoutHandles == [fixture.app])
    }
    let match = try session.firstValue(of: .url, atRole: .webArea, under: session.application,
                                       includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                                       budget: .init(maximumNodes: 2))
    #expect(match?.lastPathComponent == "first")
    #expect(fixture.timeoutHandles == [fixture.app, fixture.first])
  }
}

@Test func elementSearchPrunesSubtreesAndPreservesSiblingOrder() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  let path = try await client.withApplication(processIdentifier: 42) { session in
    var visited: [String] = []
    let result = try session.firstElement(under: session.application, includingRoot: false,
                                          missingChildren: .skipNoValueOrUnsupported) { element in
      let path = try session.read(.url, of: element).lastPathComponent
      visited.append(path)
      return path == "first" ? .prune : .match
    }
    #expect(visited == ["first", "second"])
    return try result.map { try session.read(.url, of: $0).lastPathComponent }
  }
  #expect(path == "second")
}

@Test func elementSearchBudgetStopsBeforeCallingVisitorForAnotherNode() async {
  let client = AX.Client(makeTransport: { Fixture() })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      let result = try session.firstElement(under: session.application, includingRoot: false,
                                            missingChildren: .skipNoValueOrUnsupported,
                                            budget: .init(maximumNodes: 1)) { _ in
        Issue.record("Visitor called beyond node budget")
        return .match
      }
      return result != nil
    }
    Issue.record("Expected traversal limit failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .traversalLimitReached)
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}

@Test func invalidTimeoutIsRejected() async throws {
  let client = AX.Client(configuration: .init(messagingTimeout: .zero), makeTransport: { Fixture() })
  await #expect(throws: AX.Failure.self) {
    try await client.withApplication(processIdentifier: 42) { _ in true }
  }
}

@Test func cancellationBeforeDispatch() async throws {
  let task = Task {
    withUnsafeCurrentTask { $0?.cancel() }
    return try await AX.Client(makeTransport: { Fixture() })
      .withApplication(processIdentifier: 42) { _ in true }
  }
  await #expect(throws: CancellationError.self) { try await task.value }
}

@Test func cancellationDuringReadIsObservedAfterIPC() async throws {
  let (started, continuation) = AsyncStream<Void>.makeStream()
  let release = DispatchSemaphore(value: 0)
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.onRead = {
      continuation.yield(())
      release.wait()
    }
    return fixture
  })
  let task = Task {
    try await client.withApplication(processIdentifier: 42) { try $0.windows().count }
  }
  var iterator = started.makeAsyncIterator()
  _ = await iterator.next()
  task.cancel()
  release.signal()
  await #expect(throws: CancellationError.self) { try await task.value }
  continuation.finish()
}

@Test func strictMissingPolicyThrows() async throws {
  let client = AX.Client(makeTransport: {
    let fixture = Fixture()
    fixture.missingFirstURL = true
    return fixture
  })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      try session.firstValue(of: .url, atRole: .webArea, under: session.application,
                             includingRoot: true, missingValue: .fail)
    }
    Issue.record("Expected missing-value failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .noValue)
  }
}

@Test func expiredAndForeignElementsAreRejected() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  try await client.withApplication(processIdentifier: 42) { session in
    let foreign = AX.Element(key: UUID(), scope: UUID())
    #expect(throws: AX.Failure.self) { try session.read(.role, of: foreign) }
    session.invalidate()
    #expect(throws: AX.Failure.self) { try session.windows() }
  }
}

@Test func depthAndElapsedBudgetsThrow() async throws {
  for budget in [AX.TraversalBudget(maximumDepth: 0),
                 AX.TraversalBudget(elapsedLimit: .init(secondsComponent: 0, attosecondsComponent: 1))] {
    let client = AX.Client(makeTransport: { Fixture() })
    do {
      _ = try await client.withApplication(processIdentifier: 42) { session in
        try session.firstValue(of: .url, atRole: .button, under: session.application,
                               includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                               budget: budget)
      }
      Issue.record("Expected budget exhaustion")
    } catch let failure as AX.Failure {
      #expect(failure.kind == .traversalLimitReached)
    }
  }
}

@Test func roleDecoderPreservesAnUnrecognizedRole() throws {
  let role = try AX.Attribute<AX.Role>.role.decode(.string("AXExampleCustomRole"))
  #expect(role.rawValue == "AXExampleCustomRole")
}

@Test func nativeDecoderValidatesCFTypesWithoutRemoteCalls() throws {
  let decode = AX.NativeTransport.decode
  if case .string(let value) = try decode("AXWebArea" as CFString, "AXRole") {
    #expect(value == "AXWebArea")
  } else { Issue.record("Expected string") }
  let url = URL(string: "https://example.com")!
  if case .url(let value) = try decode(url as CFURL, "AXURL") {
    #expect(value == url)
  } else { Issue.record("Expected URL") }
  let element = AXUIElementCreateApplication(getpid())
  if case .elements(let values) = try decode([element] as CFArray, "AXChildren") {
    #expect(values.count == 1)
    #expect(values[0].native.map { CFEqual($0, element) } == true)
  } else { Issue.record("Expected elements") }
  if case .elements(let values) = try decode([] as CFArray, "AXChildren") {
    #expect(values.isEmpty)
  } else { Issue.record("Expected empty elements") }
  #expect(throws: AX.Failure.self) { try decode(nil, "AXURL") }
  do {
    let value = try decode(kCFBooleanTrue, "AXURL")
    _ = try AX.Attribute<URL>.url.decode(value)
    Issue.record("Expected decoder to reject a Boolean")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .malformedValue)
    #expect(failure.operation == "AXURL")
  }
  #expect(try AX.Attribute<Bool>.focused.decode(decode(kCFBooleanTrue, "AXFocused")))
  #expect(try !AX.Attribute<Bool>.selected.decode(decode(kCFBooleanFalse, "AXSelected")))
  #expect(throws: AX.Failure.self) { try decode(["not an element"] as CFArray, "AXChildren") }
  #expect(throws: AX.Failure.self) { try decode([element, "not an element"] as CFArray, "AXChildren") }
}

private final class ConcurrencyProbe: @unchecked Sendable {
  private let lock = NSLock()
  private var running = false
  func enter() {
    lock.withLock {
      #expect(!running)
      running = true
    }
  }

  func leave() { lock.withLock { running = false } }
}

@Test func concurrentTransactionsAreSerializedOffMain() async throws {
  let probe = ConcurrencyProbe()
  let client = AX.Client(makeTransport: { Fixture() })
  try await withThrowingTaskGroup(of: Bool.self) { group in
    for _ in 0 ..< 20 {
      group.addTask {
        try await client.withApplication(processIdentifier: 42) { session in
          probe.enter()
          defer { probe.leave() }
          #expect(!Thread.isMainThread)
          return try session.windows().count == 2
        }
      }
    }
    for try await success in group { #expect(success) }
  }
}
