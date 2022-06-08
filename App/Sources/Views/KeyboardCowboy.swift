import SwiftUI
import LaunchArguments
@_exported import Inject

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
let launchArguments = LaunchArgumentsController<LaunchArgument>()

@main
struct KeyboardCowboy: App {
  @FocusState private var focus: Focus?
  private let contentStore: ContentStore
  private let engine: KeyboardCowboyEngine

  init() {
    let contentStore = ContentStore(.user())
    self.contentStore = contentStore
    self.engine = KeyboardCowboyEngine(contentStore)
    self.focus = .main(.groupComponent)
    Inject.animation = .easeInOut(duration: 0.175)
  }

  var body: some Scene {
    WindowGroup {
      ContentView(contentStore, focus: _focus) { action in
        switch action {
        case .run(let command):
          engine.run([command], serial: true)
        case .reveal(let command):
          engine.reveal([command])
        }
      }
      .equatable()
    }
  }
}
