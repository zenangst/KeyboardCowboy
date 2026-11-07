import Carbon

/// A system input source retaining the actual Carbon handle returned by lookup.
public struct InputSource {
  public let id: String
  private let source: TISInputSource

  fileprivate init(source: TISInputSource) throws {
    guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
          let id = Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? String,
          let namePointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName),
          Unmanaged<AnyObject>.fromOpaque(namePointer).takeUnretainedValue() as? String != nil else {
      throw InputSource.Error.invalidInputSource
    }
    self.id = id
    self.source = source
  }

  fileprivate func select() -> OSStatus { TISSelectInputSource(source) }
}

public extension InputSource {
  enum Error: Swift.Error {
    case invalidInputSource
    case failedToFindInputSource(id: String)
    case failedToSelect(id: String)
  }

  @MainActor
  final class Controller {
    public init() {}

    public func currentInputSource() throws -> InputSource {
      try InputSource(source: TISCopyCurrentKeyboardInputSource().takeRetainedValue())
    }

    public func findInput(_ id: String, includeAllInstalled: Bool) throws -> InputSource {
      let list = TISCreateInputSourceList([:] as CFDictionary, includeAllInstalled)?.takeRetainedValue()
      let sources = list as? [TISInputSource] ?? []
      guard let result = sources.lazy.compactMap({ try? InputSource(source: $0) }).first(where: { $0.id == id }) else {
        throw InputSource.Error.failedToFindInputSource(id: id)
      }
      return result
    }

    public func select(_ source: InputSource) throws {
      guard source.select() == noErr else {
        throw InputSource.Error.failedToSelect(id: source.id)
      }
    }
  }
}
