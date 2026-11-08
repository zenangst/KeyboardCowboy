@testable import ApplicationSystem
@testable import ApplicationsFeature
@testable import CowboyCore
import Testing

@Test func restartCancellationAfterTerminationStopsPolling() async {
  let identifier = BundleIdentifier("example.target")
  let target = Core.RunningApplication(.testing(identifier))
  let (events, continuation) = AsyncStream<String>.makeStream()
  let cancelled = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
    group.addTask {
      await Core.RunningApplication.Testing.$mock.withValue(.init(
        runningApplicationsLookup: { _ in
          continuation.yield("lookup")
          return [target]
        },
        onTerminate: { _ in
          continuation.yield("terminate")
          withUnsafeCurrentTask { $0?.cancel() }
          return true
        }
      )) {
        do {
          _ = try await Operation.Restart(.testing, retries: 2, pollingInterval: .zero)(identifier)
          return false
        } catch is CancellationError {
          return true
        } catch {
          return false
        }
      }
    }
    return await group.next() ?? false
  }
  continuation.finish()
  var recorded: [String] = []
  for await event in events { recorded.append(event) }
  #expect(cancelled)
  #expect(recorded == ["lookup", "terminate"])
}
