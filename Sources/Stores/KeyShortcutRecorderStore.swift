import Combine
import Foundation

final class KeyShortcutRecorderStore: ObservableObject {
  @Published private(set) var recording: KeyShortcutRecording?
  @Published var mode: KeyboardCowboyMode?

  private var subscription: AnyCancellable?

  func subscribe(to publisher: Published<KeyShortcutRecording?>.Publisher) {
    subscription = publisher
      .dropFirst()
      .sink { [weak self] recording in
        self?.recording = recording
      }
  }
}
