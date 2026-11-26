import AppKit
import Combine

public extension ApplicationTriggers {
  struct Snapshot: Sendable {
    public var runningBundleIdentifiers: [String]
    public var frontmostBundleIdentifier: String?

    public init(runningBundleIdentifiers: [String], frontmostBundleIdentifier: String?) {
      self.runningBundleIdentifiers = runningBundleIdentifiers
      self.frontmostBundleIdentifier = frontmostBundleIdentifier
    }
  }

  enum Change: Sendable {
    case runningApplications([String])
    case frontmostApplication(String?)
  }

  @MainActor
  struct Source {
    let snapshot: @MainActor () -> Snapshot
    let observe: @MainActor (@escaping @MainActor (Change) -> Void) -> AnyCancellable

    public init(
      snapshot: @escaping @MainActor () -> Snapshot,
      observe: @escaping @MainActor (@escaping @MainActor (Change) -> Void) -> AnyCancellable,
    ) {
      self.snapshot = snapshot
      self.observe = observe
    }

    public static func workspace(_ workspace: NSWorkspace = .shared) -> Self {
      Self(snapshot: {
        Snapshot(runningBundleIdentifiers: workspace.runningApplications.compactMap(\.bundleIdentifier),
                 frontmostBundleIdentifier: workspace.frontmostApplication?.bundleIdentifier)
      }, observe: { handler in
        let changes = workspace.publisher(for: \.runningApplications, options: [.new])
          .map { Change.runningApplications($0.compactMap(\.bundleIdentifier)) }
          .merge(with: workspace.publisher(for: \.frontmostApplication, options: [.new])
            .map { Change.frontmostApplication($0?.bundleIdentifier) })
          .receive(on: DispatchQueue.main)
          .sink { @Sendable change in
            MainActor.assumeIsolated { handler(change) }
          }
        return changes
      })
    }
  }
}
