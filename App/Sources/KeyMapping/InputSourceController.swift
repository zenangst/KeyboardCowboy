import Carbon
import Foundation

/// Based on: https://github.com/Clipy/Sauce

final class InputSourceController {
  func currentInputSource() -> InputSource {
    InputSource(source: TISCopyCurrentKeyboardInputSource().takeUnretainedValue())
  }

  func fetchInputSource(includeAllInstalled: Bool) -> [InputSource] {
    let sourceList = TISCreateInputSourceList([:] as CFDictionary, includeAllInstalled)
    guard let sources = sourceList?.takeUnretainedValue() as? [TISInputSource] else { return [] }
    return sources.map { InputSource(source: $0) }
  }

  func isInstalledInputSource(id: String) -> Bool {
    return fetchInputSource(includeAllInstalled: false).contains(where: { $0.id == id })
  }

  @discardableResult
  func installInputSource(id: String) -> Bool {
    let allInputSources = fetchInputSource(includeAllInstalled: true)
    guard let targetInputSource = allInputSources.first(where: { $0.id == id }) else { return false }
    return TISEnableInputSource(targetInputSource.source) == noErr
  }

  @discardableResult
  func uninstallInputSource(id: String) -> Bool {
    let installedInputSources = fetchInputSource(includeAllInstalled: false)
    guard let targetInputSource = installedInputSources.first(where: { $0.id == id }) else { return true }
    return TISDisableInputSource(targetInputSource.source) == noErr
  }

  @discardableResult
  func selectInputSource(id: String) -> InputSource? {
    let installedInputSources = self.fetchInputSource(includeAllInstalled: false)
    guard let targetInputSource = installedInputSources.first(where: { $0.id == id }) else {
      return nil
    }
    let result = TISSelectInputSource(targetInputSource.source) == noErr
    return result == true ? targetInputSource : nil
  }
}
