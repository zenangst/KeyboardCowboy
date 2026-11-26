import Carbon
import CoreGraphics
import Foundation

public extension KeyCodeSystem {
  /// A snapshot of a macOS Unicode keyboard layout. Take a new snapshot after
  /// an input-source change. Lookup never selects a source or posts events.
  struct Layout: Sendable {
    private let data: Data
    let keyboardType: UInt32
    private let indexes: [UInt32: Index]

    private init(data: Data, keyboardType: UInt32) {
      self.data = data
      self.keyboardType = keyboardType
      // Prepare shortcut and text-typing lookups once per layout, not per key.
      let states: [CGEventFlags] = [[], .maskShift, .maskAlternate, [.maskShift, .maskAlternate]]
      indexes = Dictionary(uniqueKeysWithValues: states.map { flags in
        let state = Self.carbonState(flags)
        return (state, Index(values: (0 ..< 128).map { Self.translate($0, state: state, data: data, keyboardType: keyboardType) }))
      })
    }

    /// Uses the active input source when it exposes a layout, otherwise the
    /// system's current keyboard layout (for input methods such as IMEs).
    @MainActor
    public static func current() throws -> Self {
      let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
      let data = source.flatMap(layoutData)
        ?? TISCopyCurrentKeyboardLayoutInputSource().map { $0.takeRetainedValue() }.flatMap(layoutData)
      guard let data else { throw LookupError.layoutUnavailable }

      return Self(data: data, keyboardType: UInt32(LMGetKbdType()))
    }

    /// Loads a named installed source without enabling or selecting it.
    @MainActor
    public init(inputSourceID: String) throws {
      let filter = [kTISPropertyInputSourceID: inputSourceID] as CFDictionary
      guard let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource],
            let source = sources.first else { throw LookupError.inputSourceUnavailable(inputSourceID) }
      guard let data = Self.layoutData(source) else { throw LookupError.layoutUnavailable }

      self.init(data: data, keyboardType: UInt32(LMGetKbdType()))
    }

    /// The literal display translation before substituting shortcut labels.
    public func rawValue(for keyCode: Int, modifiers: CGEventFlags = []) -> String? {
      guard (0 ..< 128).contains(keyCode) else { return nil }

      let state = Self.carbonState(modifiers)
      if let index = indexes[state] { return index.values[keyCode] }
      return Self.translate(keyCode, state: state, data: data, keyboardType: keyboardType)
    }

    public func displayValue(for keyCode: Int, modifiers: CGEventFlags = []) -> String? {
      if let special = KeyCodeSystem.specialKeys[keyCode] { return special }
      return Self.display(keyCode, raw: rawValue(for: keyCode, modifiers: modifiers))
    }

    /// Case-sensitive reverse lookup. Display labels distinguish named keys
    /// (for example `#1` from `1`). Raw collisions prefer the main keyboard.
    public func keyCode(for value: String, modifiers: CGEventFlags = [], matchDisplayValue: Bool = true) -> Int? {
      guard !value.isEmpty else { return nil }

      let state = Self.carbonState(modifiers)
      if let index = indexes[state] { return (matchDisplayValue ? index.display : index.raw)[value] }
      if matchDisplayValue, let special = KeyCodeSystem.specialCodes[value] { return special }
      return KeyCodeSystem.lookupOrder.first { code in
        let raw = Self.translate(code, state: state, data: data, keyboardType: keyboardType)
        return (matchDisplayValue ? Self.display(code, raw: raw) : raw) == value
      }
    }

    private struct Index: Sendable {
      let values: [String?]
      let raw: [String: Int]
      let display: [String: Int]

      init(values: [String?]) {
        self.values = values
        var raw: [String: Int] = [:]
        var display = KeyCodeSystem.specialCodes
        for code in KeyCodeSystem.lookupOrder {
          if let value = values[code], raw[value] == nil { raw[value] = code }
          if let value = Layout.display(code, raw: values[code]), display[value] == nil { display[value] = code }
        }
        self.raw = raw
        self.display = display
      }
    }

    private static func display(_ code: Int, raw: String?) -> String? {
      if let special = KeyCodeSystem.specialKeys[code] { return special }
      guard let value = raw?.trimmingCharacters(in: .controlCharacters), !value.isEmpty else { return nil }

      return value
    }

    private static func translate(_ code: Int, state: UInt32, data: Data, keyboardType: UInt32) -> String? {
      var deadKeyState: UInt32 = 0
      var length = 0
      return withUnsafeTemporaryAllocation(of: UniChar.self, capacity: 255) { characters in
        let status = data.withUnsafeBytes { bytes in
          UCKeyTranslate(
            bytes.baseAddress!.assumingMemoryBound(to: UCKeyboardLayout.self),
            UInt16(code), UInt16(kUCKeyActionDisplay), state, keyboardType,
            OptionBits(kUCKeyTranslateNoDeadKeysMask), &deadKeyState, characters.count, &length, characters.baseAddress!,
          )
        }
        guard status == noErr, length > 0 else { return nil }

        return String(decoding: characters.prefix(length), as: UTF16.self)
      }
    }

    private static func layoutData(_ source: TISInputSource) -> Data? {
      guard let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData),
            CFGetTypeID(Unmanaged<CFTypeRef>.fromOpaque(pointer).takeUnretainedValue()) == CFDataGetTypeID()
      else { return nil }

      let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
      return data.count >= MemoryLayout<UCKeyboardLayout>.size ? data : nil
    }

    private static func carbonState(_ flags: CGEventFlags) -> UInt32 {
      var state = 0
      if flags.contains(.maskShift) { state |= shiftKey }
      if flags.contains(.maskAlphaShift) { state |= alphaLock }
      if flags.contains(.maskAlternate) { state |= optionKey }
      if flags.contains(.maskControl) { state |= controlKey }
      if flags.contains(.maskCommand) { state |= cmdKey }
      return UInt32(state >> 8)
    }
  }
}
