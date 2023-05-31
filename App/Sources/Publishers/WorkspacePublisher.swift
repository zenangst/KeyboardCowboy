import Combine
import Cocoa

final class WorkspacePublisher {
  @Published private(set) var frontmostApplication: RunningApplication?
  @Published private(set) var runningApplications: [RunningApplication] = []

  private var frontmostApplicationSubscription: AnyCancellable?
  private var runningApplicationsSubscription: AnyCancellable?

  init(_ workspace: NSWorkspace = .shared) {
    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .sink { [weak self] in
        self?.frontmostApplication = $0
      }
    runningApplicationsSubscription = workspace.publisher(for: \.runningApplications)
      .sink { [weak self] in
        self?.runningApplications = $0
      }
  }
}
