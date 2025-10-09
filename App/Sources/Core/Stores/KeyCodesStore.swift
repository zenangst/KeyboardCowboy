import AppKit
import Carbon
import Combine
import Foundation
import InputSources
import KeyCodes

protocol CurrentInputSourceProviding {
  @MainActor func inputSource() throws -> TISInputSource
}

// Conform `InputSources` to `CurrentInputSourceProviding` in to make the
// implementation agnostic to the framework itself.
extension InputSourceController: CurrentInputSourceProviding {
  func inputSource() throws -> TISInputSource {
    try currentInputSource().source
  }
}

@MainActor
final class KeyCodesStore {
  private var subscription: AnyCancellable?
  private var virtualKeyContainer: VirtualKeyContainer?
  private var virtualSystemKeys = [VirtualKey]()

  private let currentInputProvider: CurrentInputSourceProviding

  init(_ currentInputProvider: CurrentInputSourceProviding) {
    self.currentInputProvider = currentInputProvider
    reloadCurrentSource()
  }

  func subscribe(to publisher: Published<UUID?>.Publisher) {
    subscription = publisher
      .sink { [weak self] _ in
        self?.reloadCurrentSource()
      }
  }

  nonisolated func specialKeys() -> [Int: String] {
    VirtualSpecialKey.keys
  }

  func virtualKey(for string: String, modifiers: [VirtualModifierKey] = [], matchDisplayValue: Bool = true) -> VirtualKey? {
    virtualKeyContainer?.valueForString(string,
                                        modifiers: modifiers,
                                        matchDisplayValue: matchDisplayValue)
  }

  func keyCode(for string: String, matchDisplayValue: Bool) -> Int? {
    virtualKeyContainer?.valueForString(string, modifier: nil,
                                        matchDisplayValue: matchDisplayValue)?.keyCode
  }

  func displayValue(for keyCode: Int, modifiers: [VirtualModifierKey]) -> String? {
    virtualKeyContainer?.valueForKeyCode(keyCode, modifiers: modifiers)?.displayValue
  }

  func displayValue(for keyCode: Int, modifier: VirtualModifierKey? = nil) -> String? {
    if let modifier {
      virtualKeyContainer?.valueForKeyCode(keyCode, modifiers: [modifier])?.displayValue
    } else {
      virtualKeyContainer?.valueForKeyCode(keyCode, modifiers: [])?.displayValue
    }
  }

  // MARK: Private methods

  private func reloadCurrentSource() {
    guard let currentInputSource = try? currentInputProvider.inputSource() else { return }

    try? mapKeys(from: currentInputSource)
  }

  private func mapKeys(from inputSource: TISInputSource) throws {
    let keyCodes = KeyCodes()
    let virtualKeyContainer = try keyCodes.mapKeyCodes(from: inputSource)
    let virtualSystemKeys = try keyCodes.systemKeys(from: inputSource)
    self.virtualKeyContainer = virtualKeyContainer
    self.virtualSystemKeys = virtualSystemKeys
  }
}
