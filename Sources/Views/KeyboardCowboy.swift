import SwiftUI
@_exported import Inject

let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil

@main
struct KeyboardCowboy: App {
  private let contentStore: ContentStore
  private let engine: KeyboardCowboyEngine

  init() {
    let contentStore = ContentStore(.user())
    self.contentStore = contentStore
    self.engine = KeyboardCowboyEngine(contentStore)
    Inject.animation = .easeInOut(duration: 0.175)
  }

  var body: some Scene {
    WindowGroup {
      ContentView(contentStore) { action in
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
