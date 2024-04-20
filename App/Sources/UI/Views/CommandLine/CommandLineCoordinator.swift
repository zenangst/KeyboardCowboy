import AppKit
import Carbon
import Combine
import KeyCodes
import InputSources
import Foundation
import SwiftUI

final class CommandLineCoordinator: NSObject, ObservableObject, NSWindowDelegate, CommandLineWindowEventDelegate, @unchecked Sendable {
  @Published var input: String = ""
  @MainActor
  @Published var data: CommandLineViewModel = .init(kind: nil, results: [])

  @Published var selection: Int = 0

  @MainActor
  static private(set) var shared: CommandLineCoordinator = .init()

  private let applicationRunner: ApplicationCommandRunner

  @MainActor
  lazy var windowController: NSWindowController = {
    let window = CommandLineWindow(.init(width: 200, height: 200), rootView: CommandLineView(coordinator: CommandLineCoordinator.shared))
    window.eventDelegate = self
    let windowController = NSWindowController(window: window)
    windowController.windowFrameAutosaveName = "CommandLineWindow"
    return windowController
  }()

  private let applicationStore = ApplicationStore.shared
  private var subscription: AnyCancellable?
  private var task: Task<Void, Error>?

  @MainActor
  private override init() {
    self.applicationRunner = ApplicationCommandRunner(
      scriptCommandRunner: .init(),
      keyboard: .init(store: KeyCodesStore(InputSourceController())),
      workspace: NSWorkspace.shared
    )
    super.init()
    subscription = $input
      .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
      .sink { [weak self] newInput in
        guard let self else { return }
        Task { @MainActor in
          await self.handleInputDidChange(newInput)
        }
    }

    Task { await applicationStore.load() }
  }

  @MainActor
  func show(_ action: CommandLineAction) async -> String {
    if windowController.window?.isVisible == true {
      windowController.close()
      return ""
    }

    let snapshot = await UserSpace.shared.snapshot(resolveUserEnvironment: true)
    if !snapshot.selectedText.isEmpty {
      input = snapshot.selectedText
    }

    windowController.showWindow(nil)
    windowController.window?.delegate = self
    windowController.window?.makeKeyAndOrderFront(nil)
    KeyboardCowboy.activate(setActivationPolicy: false)
    return ""
  }

  @MainActor
  func run() {
    Task {
      let _ = try? await task?.value
      switch data.kind {
      case .fallback:
        if case .search(let kind) = data.results[selection],
           let url = URL(string: "\(kind.prefix)\(kind.searchString)") {
          NSWorkspace.shared.open(url)
        }
      case .keyboard:
        break
      case .app:
        let result = data.results[selection]
        switch result {
        case .app(let application):
          try? await applicationRunner
            .run(.init(application: application), 
                 checkCancellation: false)
        default: break
        }
      case .url:
        if case .url(let url) = data.results[selection] {
          var urlString = url.absoluteString

          if !urlString.contains("://") {
            urlString = "https://" + urlString
          }

          guard let newUrl = URL(string: urlString) else { return }

          NSWorkspace.shared.open(newUrl)
        }
      case .none:
        break
      }

      windowController.window?.close()
    }
  }

  // MARK: CommandLineWindowEventDelegate

  @MainActor
  func shouldConsumeEvent(_ event: NSEvent) -> Bool {
    switch Int(event.keyCode) {
    case kVK_Escape:
      if event.type == .keyDown {
        windowController.close()
      }
      return true
    case kVK_UpArrow:
      if event.type == .keyDown {
        let newSelection = selection - 1
        selection = max(0, newSelection)
      }
      return true
    case kVK_DownArrow:
      if event.type == .keyDown {
        let newSelection = selection + 1
        selection = min(data.results.count - 1, newSelection)
      }
      return true
    default:
      return false
    }
  }

  // MARK: NSWindowDelegate

  func windowDidResignKey(_ notification: Notification) {
    windowController.close()

    let frontMostOwningMenubarApplication = NSWorkspace.shared.runningApplications
      .first(where: { $0.ownsMenuBar })

    frontMostOwningMenubarApplication?.activate()
  }

  // MARK: Private methods

  func handleInputDidChange(_ newInput: String) async {
    guard !newInput.isEmpty else {
      Task { @MainActor in
        data.kind = .none
        data.results = []
      }
      return
    }

    if newInput.hasPrefix(":") {
      Task { @MainActor in
        data.kind = .keyboard
      }
      return
    }

    if let components = URLComponents(string: newInput),
       let url = components.url {

      let split = newInput.split(separator: ".")
      if split.count > 1 && !newInput.contains(".app") {
        Task { @MainActor in
          data.kind = .url
          withAnimation(.smooth(duration: 0.1)) {
            data.results = [.url(url)]
          }
        }
        return
      }
    }

    task = Task(priority: .high) {
      let apps = applicationStore.apps()
      let searchString = newInput.lowercased()
      let matches = apps.filter({
        $0.bundleIdentifier.lowercased().contains(searchString) ||
        $0.path.lowercased().contains(searchString) ||
        $0.displayName.lowercased().hasPrefix(searchString)
      })

      try Task.checkCancellation()

      var results = matches.map {
        CommandLineViewModel.Result.app($0)
      }

      try Task.checkCancellation()

      let kind: CommandLineViewModel.Kind

      if results.isEmpty {
        results.append(
          .search(
            .init(id: "Google", name: "Google", text: "Google '\(newInput)'",
                  prefix: "https://www.google.com/search?q=", searchString: newInput)
          )
        )
        results.append(
          .search(
            .init(id: "GitHub", name: "GitHub", text: "Seach GitHub for '\(newInput)'",
                  prefix: "https://www.github.com/search?q=", searchString: newInput)
          )
        )
        results.append(
          .search(
            .init(id: "iMDB", name: "iMDB", text: "Seach iMDB for '\(newInput)'",
                  prefix: "https://www.imdb.com/find/?q=", searchString: newInput)
          )
        )
        kind = .fallback
      } else {
        kind = .app
      }

      let finalResults = results

      await MainActor.run {
        withAnimation(.smooth(duration: 0.1)) {
          data.results = finalResults
        }
        data.kind = kind
      }
    }
  }
}
