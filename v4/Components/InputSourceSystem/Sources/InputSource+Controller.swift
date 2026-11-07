import Carbon

/// A system input source retaining the actual Carbon handle returned by lookup.
public struct InputSource {
  public let id: String
  private let source: TISInputSource?
  #if DEBUG
    public let testingToken: String?

    init(testingID: String, token: String) {
      id = testingID
      source = nil
      testingToken = token
    }
  #endif

  fileprivate init(source: TISInputSource) throws {
    guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
          let id = Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? String,
          let namePointer = TISGetInputSourceProperty(source, kTISPropertyLocalizedName),
          Unmanaged<AnyObject>.fromOpaque(namePointer).takeUnretainedValue() as? String != nil else {
      throw InputSource.Error.invalidInputSource
    }
    self.id = id
    self.source = source
    #if DEBUG
      testingToken = nil
    #endif
  }

  fileprivate func select() -> OSStatus {
    guard let source else { return -1 }
    return TISSelectInputSource(source)
  }
}

public extension InputSource {
  enum Error: Swift.Error {
    case invalidInputSource
    case failedToFindInputSource(id: String)
    case failedToSelect(id: String)
  }

  @MainActor
  final class Controller {
    #if DEBUG
      private let isTesting: Bool
      public init() { isTesting = false }
      private init(isTesting: Bool) { self.isTesting = isTesting }
      public static func testing() -> Controller { Controller(isTesting: true) }
    #else
      public init() {}
    #endif

    public func currentInputSource() throws -> InputSource {
      #if DEBUG
        if isTesting { return try Testing.mock.current() }
      #endif
      return try InputSource(source: TISCopyCurrentKeyboardInputSource().takeRetainedValue())
    }

    public func findInput(_ id: String, includeAllInstalled: Bool) throws -> InputSource {
      #if DEBUG
        if isTesting { return try Testing.mock.find(id, includeAllInstalled) }
      #endif
      let list = TISCreateInputSourceList([:] as CFDictionary, includeAllInstalled)?.takeRetainedValue()
      let sources = list as? [TISInputSource] ?? []
      guard let result = sources.lazy.compactMap({ try? InputSource(source: $0) }).first(where: { $0.id == id }) else {
        throw InputSource.Error.failedToFindInputSource(id: id)
      }
      return result
    }

    public func select(_ source: InputSource) throws {
      #if DEBUG
        if isTesting { return try Testing.mock.select(source) }
      #endif
      guard source.select() == noErr else {
        throw InputSource.Error.failedToSelect(id: source.id)
      }
    }
  }
}
