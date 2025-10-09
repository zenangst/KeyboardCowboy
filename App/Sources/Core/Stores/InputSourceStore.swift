import Combine
import Foundation
import InputSources

@MainActor
final class InputSourceStore: ObservableObject {
  @Published private(set) var inputSources = [InputSource]()

  private var subscription: AnyCancellable?
  private let controller: InputSourceController

  init() {
    controller = InputSourceController()
    index()
  }

  func subscribe(to publisher: Published<UUID?>.Publisher) {
    subscription = publisher.sink { [weak self] _ in
      self?.index()
    }
  }

  private func index() {
    let forbiddenIds = [
      "com.apple.PressAndHold",
      "com.apple.CharacterPaletteIM",
      "com.apple.inputmethod.ironwood",
    ]

    inputSources = controller.fetchInputSources(includeAllInstalled: false)
      .reduce(into: [InputSource]()) { partialResult, inputSource in
        guard !forbiddenIds.contains(inputSource.id),
              inputSource.isSelectCapable,
              inputSource.isASCIICapable else { return }

        partialResult.append(inputSource)
      }
      .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
  }
}
