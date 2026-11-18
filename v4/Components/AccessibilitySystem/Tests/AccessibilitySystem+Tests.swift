@testable import AccessibilitySystem
import ApplicationServices
import Foundation
import Testing

private typealias AX = AccessibilitySystem

// A fresh fixture is constructed on the worker for every transaction.
private final class Fixture: AX.Transport {
  let app = AX.Handle()
  let first = AX.Handle()
  let second = AX.Handle()
  let nested = AX.Handle()
  var timeoutHandles: Set<AX.Handle> = []
  var failWindows = false
  var failTimeout = false
  var missingFirstURL = false
  var cycle = false
  var malformedRole = false
  var onRead: (() -> Void)?

  func application(_ pid: Int32) -> AX.Handle { app }

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
    if name == "AXWindows" {
      if failWindows {
        throw AX.Failure(.cannotComplete, operation: name, rawAXStatus: -25204)
      }
      return .elements([first, second])
    }

    if name == "AXChildren" {
      if handle == app { return .elements([first, second]) }
      if handle == first { return .elements([nested]) }
      if cycle { return .elements([app]) }
      throw AX.Failure(.attributeUnsupported, operation: name)
    }

    if name == "AXRole" {
      if malformedRole { return .malformed }
      return .string(handle == app ? "AXApplication" : "AXWebArea")
    }

    if name == "AXURL" {
      if handle == first && missingFirstURL { throw AX.Failure(.noValue, operation: name) }
      let path = handle == first ? "first" : handle == second ? "second" : "nested"
      return .url(URL(string: "https://example.com/\(path)")!)
    }

    throw AX.Failure(.attributeUnsupported, operation: name)
  }
}

@Test func orderedWindowsAndTypedReads() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  let urls = try await client.withApplication(processIdentifier: 42) { session in
    try session.windows().map { try session.read(.url, of: $0).absoluteString }
  }
  #expect(urls == ["https://example.com/first", "https://example.com/second"])
}

@Test func rootInclusionAndPreorder() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  let values = try await client.withApplication(processIdentifier: 42) { session in
    let root = try session.windows()[0]
    let included = try session.firstValue(of: .url, atRole: "AXWebArea", under: root,
                                          includingRoot: true, missingValue: .skipNoValueOrUnsupported)
    let excluded = try session.firstValue(of: .url, atRole: "AXWebArea", under: root,
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
    try session.firstValue(of: .url, atRole: "AXWebArea", under: session.application,
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
      try session.firstValue(of: .url, atRole: "AXWebArea", under: session.application,
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
    try session.firstValue(of: .url, atRole: "AXButton", under: session.application,
                           includingRoot: true, missingValue: .skipNoValueOrUnsupported)
  }
  #expect(result == nil)
}

@Test func budgetExhaustionIsNotNoMatch() async throws {
  let client = AX.Client(makeTransport: { Fixture() })
  do {
    _ = try await client.withApplication(processIdentifier: 42) { session in
      try session.firstValue(of: .url, atRole: "AXButton", under: session.application,
                             includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                             budget: .init(maximumNodes: 1))
    }
    Issue.record("Expected budget failure")
  } catch let failure as AX.Failure {
    #expect(failure.kind == .traversalLimitReached)
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
      try session.firstValue(of: .url, atRole: "AXWebArea", under: session.application,
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
        try session.firstValue(of: .url, atRole: "AXButton", under: session.application,
                               includingRoot: true, missingValue: .skipNoValueOrUnsupported,
                               budget: budget)
      }
      Issue.record("Expected budget exhaustion")
    } catch let failure as AX.Failure {
      #expect(failure.kind == .traversalLimitReached)
    }
  }
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
  #expect(throws: AX.Failure.self) { try decode(nil, "AXURL") }
  #expect(throws: AX.Failure.self) { try decode(kCFBooleanTrue, "AXURL") }
  #expect(throws: AX.Failure.self) { try decode(["not an element"] as CFArray, "AXChildren") }
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
