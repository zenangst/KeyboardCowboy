import AXEssibility
import AppKit
import Apps
import Carbon
import Cocoa
import Combine
import Foundation
import InputSources
import KeyCodes
import MachPort

enum UserSpaceError: Error {
  case unableToResolveFrontMostApplication
  case unableToGetSelection
  case unableToGetDocumentPath
}

final class UserSpace: @unchecked Sendable {
  enum EnvironmentKey: String, CaseIterable {
    case currentWorkingDirectory = "CURRENT_WORKING_DIRECTORY"
    case directory = "DIRECTORY"
    case file = "FILE"
    case filepath = "FILEPATH"
    case filename = "FILENAME"
    case `extension` = "EXTENSION"
    case selectedText = "SELECTED_TEXT"
    case pasteboard = "PASTEBOARD"
    case lastKey = "LAST_KEY"
    case lastKeyCode = "LAST_KEY_CODE"

    var asTextVariable: String { "$\(rawValue)" }
    var help: String {
      switch self {
      case .currentWorkingDirectory: "The current working directory"
      case .directory: "The current directory"
      case .file: "The current file"
      case .filepath: "The path to the file"
      case .filename: "The file name"
      case .extension: "The file extension"
      case .selectedText: "The current selected text"
      case .pasteboard: "The contents of the pasteboard"
      case .lastKey: "The last key pressed"
      case .lastKeyCode: "The last key code pressed"
      }
    }
  }

  struct Application: Equatable, @unchecked Sendable {
    let ref: RunningApplication
    let bundleIdentifier: String
    let name: String
    let path: String

    @MainActor
    static let current: UserSpace.Application = NSRunningApplication.currentAsApplication()

    static func ==(lhs: Application, rhs: Application) -> Bool {
      lhs.bundleIdentifier == rhs.bundleIdentifier &&
      lhs.name == rhs.name &&
      lhs.path == rhs.path
    }
  }
  struct Snapshot {
    let documentPath: String?
    let frontmostApplication: Application
    let modes: [UserMode]
    let previousApplication: Application
    let selectedText: String
    let selections: [String]
    let windows: WindowStoreSnapshot

    init(documentPath: String? = nil,
         frontmostApplication: Application,
         modes: [UserMode] = [],
         previousApplication: Application,
         selectedText: String = "",
         selections: [String] = [],
         specialKeys: [Int] = [],
         windows: WindowStoreSnapshot = WindowStoreSnapshot(
          frontmostApplicationWindows: [],
          visibleWindowsInStage: [],
          visibleWindowsInSpace: []
         )) {
      self.documentPath = documentPath
      self.frontmostApplication = frontmostApplication
      self.modes = modes
      self.previousApplication = previousApplication
      self.selectedText = selectedText
      self.selections = selections
      self.windows = windows
    }

    @MainActor
    func interpolateUserSpaceVariables(_ value: String, runtimeDictionary: [String: String]) -> String {
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

      if let pasteboard = NSPasteboard.general.string(forType: .string) {
        interpolatedString = interpolatedString.replacingOccurrences(of: .pasteboard, with: pasteboard)
      }

      for (key, value) in runtimeDictionary {
        interpolatedString = interpolatedString.replacingOccurrences(of: "$"+key, with: value)
      }

      if let cgEvent = UserSpace.shared.cgEvent {
        let keyCodes = UserSpace.shared.keyCodes
        let specialKeys = Array(UserSpace.shared.keyCodes.specialKeys().keys)
        let keyCode = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))
        interpolatedString = interpolatedString.replacingOccurrences(of: .lastKeyCode, with: "\(keyCode)")
        let modifiers = VirtualModifierKey.modifiers(for: keyCode, flags: cgEvent.flags, specialKeys: specialKeys)
        if let displayValue = keyCodes.displayValue(for: keyCode, modifiers: modifiers) ?? keyCodes.displayValue(for: keyCode, modifiers: []) {
          interpolatedString = interpolatedString.replacingOccurrences(of: .lastKey, with: "\(displayValue)")
        }
      }

      return interpolatedString
    }

    func terminalEnvironment() async -> [String: String] {
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

      if let pasteboard = NSPasteboard.general.string(forType: .string) {
        environment[.pasteboard] = pasteboard
      }

      return environment
    }
  }

  static func resolveEnvironmentKeys(_ input: String) -> Set<EnvironmentKey> {
    let parts = input.split(separator: " ").map(String.init)
    let keys = parts.reduce(into: Set<EnvironmentKey>()) { partialResult, input in
      let variable = String(input.dropFirst(1))
      if let key = EnvironmentKey(rawValue: variable) {
        partialResult.insert(key)
      }
    }
    return keys
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

  @MainActor
  static let shared = UserSpace()

  @Published private(set) var frontmostApplication: Application
  @Published private(set) var previousApplication: Application
  @Published private(set) var runningApplications: [Application]
  public let userModesPublisher = UserModesPublisher([])
  private(set) var userModes: [UserMode] = []

  fileprivate let keyCodes: KeycodeLocating
  fileprivate var cgEvent: CGEvent?

  private var frontmostApplicationSubscription: AnyCancellable?
  private var configurationSubscription: AnyCancellable?
  private var runningApplicationsSubscription: AnyCancellable?
  private var machPortEventSubscription: AnyCancellable?

  var machPort: MachPortEventController?

  @MainActor
  private init(workspace: NSWorkspace = .shared) {
    frontmostApplication = .current
    previousApplication = .current
    runningApplications = [Application.current]
    keyCodes = KeyCodesStore(InputSourceController())

    frontmostApplicationSubscription = workspace.publisher(for: \.frontmostApplication)
      .compactMap { $0 }
      .sink { [weak self] runningApplication in
        guard let self else { return }
        Task { @MainActor in
          guard let newApplication = runningApplication.asApplication() else { return }
          self.previousApplication = self.frontmostApplication
          self.frontmostApplication = newApplication
        }
      }
    runningApplicationsSubscription = workspace.publisher(for: \.runningApplications)
      .sink { [weak self] applications in
        guard let self else { return }
        Task { @MainActor in
          let newApplications = applications.compactMap { $0.asApplication() }
          self.runningApplications = newApplications
        }
      }
  }

  func subscribe(to publisher: Published<CGEvent?>.Publisher) {
    machPortEventSubscription = publisher
      .compactMap { $0 }
      .sink { [weak self] event in
        self?.cgEvent = event
      }
  }

#if DEBUG
  func injectRunningApplications(_ runningApplications: [Application]) {
    self.runningApplications = runningApplications
  }

  func injectFrontmostApplication(_ frontmostApplication: Application) {
    self.frontmostApplication = frontmostApplication
  }
#endif

  @MainActor
  func snapshot(resolveUserEnvironment: Bool, refreshWindows: Bool = false) async -> Snapshot {
    Benchmark.shared.start("snapshot: \(resolveUserEnvironment)")
    defer { Benchmark.shared.stop("snapshot: \(resolveUserEnvironment)") }
    var selections = [String]()
    var documentPath: String?
    var selectedText: String = ""

    if resolveUserEnvironment,
       let frontmostApplication = try? frontmostRunningApplication() {
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

    let windows = WindowStore.shared.snapshot(refresh: refreshWindows)

    return Snapshot(documentPath: documentPath,
                    frontmostApplication: frontmostApplication,
                    modes: userModes,
                    previousApplication: previousApplication,
                    selectedText: selectedText,
                    selections: selections,
                    windows: windows)
  }

  func subscribe(to publisher: Published<KeyboardCowboyConfiguration>.Publisher) {
    configurationSubscription = publisher
      .sink { [weak self] configuration in
        guard let self = self else { return }
        Task { @MainActor in
          let currentModes = configuration.userModes
            .map { UserMode(id: $0.id, name: $0.name, isEnabled: false) }
            .sorted(by: { $0.name < $1.name })
          self.userModes = currentModes
        }
      }
  }

  @MainActor
  func setUserModes(_ userModes: [UserMode]) {
    self.userModes = userModes

    let active = userModes.filter(\.isEnabled)

    UserModeWindow.shared.show(active)
  }

  // MARK: - Private methods

  private func frontmostRunningApplication() throws -> NSRunningApplication {
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
    do {
      let focusedElement = try systemElement.focusedUIElement()
      var selectedText = focusedElement.selectedText()

      let clipboardValidGroups = [
        "AXWebArea", "AXGroup"
      ]

      if selectedText == nil && clipboardValidGroups.contains(focusedElement.role ?? "") {
        selectedText = try await selectedTextFromClipboard()
      }

      return selectedText ?? ""
    } catch {
      return try await selectedTextFromClipboard()
    }
  }

  private func selectedTextFromClipboard() async throws -> String {
    let originalPasteboardContents = await Task { @MainActor in
      NSPasteboard.general.string(forType: .string)
    }.value

    _ = try? machPort?.post(kVK_ANSI_C, type: .keyDown, flags: .maskCommand)
    _ = try? machPort?.post(kVK_ANSI_C, type: .keyUp, flags: .maskCommand)
    try await Task.sleep(for: .milliseconds(50))

    guard let selectedText = NSPasteboard.general.string(forType: .string) else {
      throw NSError(domain: "com.zenangst.Keyboard-Cowboy.Userspace", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to read from clipboard."])
    }

    if selectedText == originalPasteboardContents {
      return ""
    }

    if let originalPasteboardContents {
      Task.detached { @MainActor [originalPasteboardContents] in
        try await Task.sleep(for: .seconds(0.2))
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(originalPasteboardContents, forType: .string)
      }
    }

    return selectedText
  }
}

fileprivate extension UserSpace {
  @MainActor
  static var cache: [String: RunningApplicationCache] = [:]
}

fileprivate struct RunningApplicationCache {
  let name: String
  let path: String
  let bundleIdentifier: String
}

extension RunningApplication {
  @MainActor
  static func currentAsApplication() -> UserSpace.Application {
    if let entry = UserSpace.cache[Bundle.main.bundleIdentifier!] {
      return UserSpace.Application(
        ref: Self.currentApp,
        bundleIdentifier: Bundle.main.bundleIdentifier!,
        name: entry.name,
        path: entry.path
      )
    }

    let userSpaceApplication: UserSpace.Application = .init(
      ref: Self.currentApp,
      bundleIdentifier: Bundle.main.bundleIdentifier!,
      name: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "",
      path: Bundle.main.bundlePath
    )

    UserSpace.cache[userSpaceApplication.bundleIdentifier] = .init(
      name: userSpaceApplication.name,
      path: userSpaceApplication.path,
      bundleIdentifier: userSpaceApplication.bundleIdentifier
    )

    return userSpaceApplication
  }

  @MainActor
  func asApplication() -> UserSpace.Application? {
    if let bundleIdentifier = bundleIdentifier {
      if let userSpaceApplication = UserSpace.cache[bundleIdentifier] {
        return UserSpace.Application(
          ref: self,
          bundleIdentifier: bundleIdentifier,
          name: userSpaceApplication.name,
          path: userSpaceApplication.path
        )
      } else if let name = localizedName,
                let path = bundleURL?.path().removingPercentEncoding {

        UserSpace.cache[bundleIdentifier] = RunningApplicationCache(
          name: name,
          path: path,
          bundleIdentifier: bundleIdentifier
        )

        return UserSpace.Application(
          ref: self,
          bundleIdentifier: bundleIdentifier,
          name: name,
          path: path
        )
      }
    }
    return nil
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
