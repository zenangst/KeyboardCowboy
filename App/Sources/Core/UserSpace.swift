import AXEssibility
import AppKit
import Apps
import Carbon
import Cocoa
import Combine
import Foundation
import MachPort

enum UserSpaceError: Error {
  case unableToResolveFrontMostApplication
  case unableToGetSelection
  case unableToGetDocumentPath
}

final class UserSpace: Sendable {
  enum EnvironmentKey: String, CaseIterable {
    case currentWorkingDirectory = "CURRENT_WORKING_DIRECTORY"
    case directory = "DIRECTORY"
    case file = "FILE"
    case filepath = "FILEPATH"
    case filename = "FILENAME"
    case `extension` = "EXTENSION"
    case selectedText = "SELECTED_TEXT"

    var asTextVariable: String { "$\(rawValue)" }
  }

  struct Application: @unchecked Sendable {
    let ref: NSRunningApplication
    let bundleIdentifier: String
    let name: String
    let path: String

    static let current: Application = NSRunningApplication.currentAsApplication()
  }
  struct Snapshot {
    let documentPath: String?
    let frontMostApplication: Application
    let modes: [UserMode]
    let previousApplication: Application
    let selectedText: String
    let selections: [String]
    let windows: WindowStoreSnapshot

    init(
      documentPath: String? = nil,
      frontMostApplication: Application = .current,
      modes: [UserMode] = [],
      previousApplication: Application = .current,
      selectedText: String = "",
      selections: [String] = [],
      windows: WindowStoreSnapshot = WindowStoreSnapshot(
        frontMostApplicationWindows: [],
        visibleWindowsInStage: [],
        visibleWindowsInSpace: []
      )
    ) {
      self.documentPath = documentPath
      self.frontMostApplication = frontMostApplication
      self.modes = modes
      self.previousApplication = previousApplication
      self.selectedText = selectedText
      self.selections = selections
      self.windows = windows
    }

    func interpolateUserSpaceVariables(_ value: String) -> String {
      var interpolatedString = value.replacingOccurrences(of: .selectedText, with: selectedText)

      if let filePath = documentPath, let url = URL(string: filePath) {
        // Attempt to create URLComponents from the URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          // Extract the directory from the path, replacing any URL-encoded spaces
          let directory = (components.path as NSString)
            .replacingOccurrences(of: "%20", with: " ")
          // Replace placeholders in the interpolated string with actual values
          let lastPathComponent = (url.lastPathComponent as NSString)
          let cwd = lastPathComponent.contains(".")
              ? (directory as NSString).deletingLastPathComponent
              : directory

          interpolatedString = interpolatedString
            .replacingOccurrences(of: .currentWorkingDirectory, with: cwd)
            .replacingOccurrences(of: .directory, with: (directory as NSString).deletingLastPathComponent)
            .replacingOccurrences(of: .filepath, with: components.path.replacingOccurrences(of: "%20", with: " "))
            .replacingOccurrences(of: .filename, with: (url.lastPathComponent as NSString).deletingPathExtension)
            .replacingOccurrences(of: .file, with: lastPathComponent as String)
            .replacingOccurrences(of: .filepath, with: (url.lastPathComponent as NSString).pathExtension)
            .replacingOccurrences(of: .extension, with: (url.lastPathComponent as NSString).pathExtension)
        }
      }
      return interpolatedString
    }

    func terminalEnvironment() -> [String: String] {
      var environment = ProcessInfo.processInfo.environment
      environment["TERM"] = "xterm-256color"
      environment[.selectedText] = selectedText

      if let filePath = documentPath {
        let url = URL(filePath: filePath)
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          let directory = (components.path as NSString)
            .replacingOccurrences(of: "%20", with: " ")
          let lastPathComponent = (url.lastPathComponent as NSString)
          let cwd = lastPathComponent.contains(".")
          ? (directory as NSString).deletingLastPathComponent
          : directory

          environment[.currentWorkingDirectory] = cwd
          environment[.directory] = (directory as NSString).deletingLastPathComponent
          environment[.file] = url.lastPathComponent
          environment[.filepath] = components.path.replacingOccurrences(of: "%20", with: " ")
          environment[.filename] = (url.lastPathComponent as NSString).deletingPathExtension
          environment[.extension] = (url.lastPathComponent as NSString).pathExtension
        }
      }

      return environment
    }
  }

  final class UserModesPublisher: ObservableObject {
    @Published private(set) var activeModes: [UserMode] = []

    init(_ activeModes: [UserMode]) {
      self.activeModes = activeModes
    }

    func publish(_ newModes: [UserMode]) {
      self.activeModes = newModes
    }
  }

  static let shared = UserSpace()

  @Published private(set) var frontMostApplication: Application = .current
  @Published private(set) var previousApplication: Application = .current
  @Published private(set) var runningApplications: [Application] = [Application.current]
  public let userModesPublisher = UserModesPublisher([])
  private(set) var userModes: [UserMode] = []
  private var frontmostApplicationSubscription: AnyCancellable?
  private var configurationSubscription: AnyCancellable?
  private var runningApplicationsSubscription: AnyCancellable?

  var machPort: MachPortEventController?

  private init(workspace: NSWorkspace = .shared) {
    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .sink { [weak self] runningApplication in
        guard let self, let newApplication = runningApplication.asApplication() else { return }
        previousApplication = frontMostApplication
        frontMostApplication = newApplication
      }
    runningApplicationsSubscription = workspace.publisher(for: \.runningApplications)
      .sink { [weak self] applications in
        guard let self else { return }
        let newApplications = applications.compactMap { $0.asApplication() }
        runningApplications = newApplications
      }
  }

#if DEBUG
  func injectRunningApplications(_ runningApplications: [Application]) {
    self.runningApplications = runningApplications
  }

  func injectFrontmostApplication(_ frontmostApplication: Application) {
    self.frontMostApplication = frontmostApplication
  }
#endif

  @MainActor
  func snapshot(resolveUserEnvironment: Bool) async -> Snapshot {
    Benchmark.shared.start("snapshot: \(resolveUserEnvironment)")
    defer { Benchmark.shared.stop("snapshot: \(resolveUserEnvironment)") }
    var selections = [String]()
    var documentPath: String?
    var selectedText: String = ""

    if resolveUserEnvironment,
        let frontmostApplication = try? frontmostApplication() {
      if let documentPathFromAX = try? self.documentPath(for: frontmostApplication) {
        documentPath = documentPathFromAX
      } else if let bundleIdentifier = frontmostApplication.bundleIdentifier {
        // Only invoke this if the user isn't dragging using the mouse.
        if !MouseMonitor.shared.isDraggingUsingTheMouse {
          ScriptingBridgeResolver.resolve(
            bundleIdentifier,
            firstUrl: &documentPath,
            selections: &selections
          )
        }
      }

      if let resolvedText = try? await self.selectedText() {
        selectedText = resolvedText
      }
    }

    let windows = WindowStore.shared.snapshot()

    return Snapshot(documentPath: documentPath,
                    frontMostApplication: frontMostApplication,
                    previousApplication: previousApplication,
                    selectedText: selectedText,
                    selections: selections,
                    windows: windows)
  }

  func subscribe(to publisher: Published<KeyboardCowboyConfiguration>.Publisher) {
    configurationSubscription = publisher
      .sink { [weak self] configuration in
        guard let self = self else { return }
        Task {
          await MainActor.run {
            let currentModes = configuration.userModes
              .map { UserMode(id: $0.id, name: $0.name, isEnabled: false) }
              .sorted(by: { $0.name < $1.name })
            self.userModes = currentModes
          }
        }
      }
  }

  @MainActor
  func setUserModes(_ userModes: [UserMode]) {
    self.userModes = userModes

    let active = userModes.filter(\.isEnabled)

    UserModesBezelController.shared.show(active)
  }

  // MARK: - Private methods

  private func frontmostApplication() throws -> NSRunningApplication {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    return frontmostApplication
  }

  private func currentApplication(for runningApplication: NSRunningApplication) throws -> AppAccessibilityElement {
    return AppAccessibilityElement(runningApplication.processIdentifier)
  }

  private func documentPath(for runningApplication: NSRunningApplication) throws -> String? {
    try currentApplication(for: runningApplication)
      .focusedWindow()
      .document
  }

  private func selectedText() async throws -> String {
    let systemElement = SystemAccessibilityElement()
    let focusedElement = try systemElement.focusedUIElement()
    var selectedText = focusedElement.selectedText()
    if selectedText == nil && (try? focusedElement.value(.role, as: String.self)) == "AXWebArea" {
      // MARK: Fix this
      // It doesn't work well in Safari.
//      selectedText = try await selectedTextFromClipboard()
    }

    return selectedText ?? ""
  }

  private func selectedTextFromClipboard() async throws -> String {
    let originalPasteboardContents = await MainActor.run {
      NSPasteboard.general.string(forType: .string)
    }

    try? machPort?.post(kVK_ANSI_C, type: .keyDown, flags: .maskCommand)
    try? machPort?.post(kVK_ANSI_C, type: .keyUp, flags: .maskCommand)

    try await Task.sleep(for: .seconds(0.1))

    guard let selectedText = NSPasteboard.general.string(forType: .string) else {
      throw NSError(domain: "com.zenangst.Keyboard-Cowboy.Userspace", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read from clipboard."])
    }

    if let originalContents = originalPasteboardContents {
      await MainActor.run {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(originalContents, forType: .string)
      }
    }

    return selectedText
  }
}


fileprivate extension NSRunningApplication {
  static func currentAsApplication() -> UserSpace.Application {
    .init(
      ref: .current,
      bundleIdentifier: Bundle.main.bundleIdentifier!,
      name: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "",
      path: Bundle.main.bundlePath
    )
  }

  func asApplication() -> UserSpace.Application? {
    if let bundleIdentifier = bundleIdentifier,
       let name = localizedName,
       let path = bundleURL?.path() {
          UserSpace.Application(
            ref: self,
            bundleIdentifier: bundleIdentifier,
            name: name,
            path: path
          )
    } else {
      nil
    }
  }
}

extension UserSpace.Application {
  func asApplication() -> Application {
    Application(bundleIdentifier: bundleIdentifier,
                bundleName: name,
                displayName: name,
                path: path)
  }
}

private extension Dictionary<String, String> {
  subscript(_ key: UserSpace.EnvironmentKey) -> String? {
    get { self[key.rawValue] }
    set { self[key.rawValue] = newValue }
  }
}

private extension String {
  func replacingOccurrences(of envKey: UserSpace.EnvironmentKey, with replacement: String) -> String {
    replacingOccurrences(of: envKey.asTextVariable, with: replacement)
  }
}
