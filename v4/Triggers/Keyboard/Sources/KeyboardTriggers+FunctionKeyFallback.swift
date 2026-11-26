import CoreGraphics

extension KeyboardTriggers.Signature {
  var functionKeyFallbacks: [Self] {
    guard KeyboardTriggers.Compiler.functionKeys.contains(Int(keyCode)) else { return [] }
    let toggled = flags ^ CGEventFlags.maskSecondaryFn.rawValue
    let known = flags & Self.knownFlags
    return known == flags || known == toggled
      ? [Self(keyCode: keyCode, flags: toggled)]
      : [Self(keyCode: keyCode, flags: toggled), Self(keyCode: keyCode, flags: known)]
  }

  private static let knownFlags = KeyboardTriggers.Modifier.allCases.reduce(
    into: CGEventFlags([.maskHelp, .maskNumericPad, .maskNonCoalesced]),
  ) { $0.formUnion($1.flags) }.rawValue
}
