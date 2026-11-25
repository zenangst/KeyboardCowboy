public enum BuiltIn {
  public enum ModeAction: String, Sendable {
    case enable, disable, toggle
  }

  public enum ModeError: Error, Equatable {
    case unableToResolveMode
  }

  /// Applies changes to live mode records. The host owns storage and presentation.
  @MainActor
  public struct ModeExecutor<Mode> {
    private let id: KeyPath<Mode, String>
    private let isEnabled: WritableKeyPath<Mode, Bool>
    private let readModes: @MainActor () -> [Mode]
    private let updateModes: @MainActor ([Mode]) -> Void

    public init(
      id: KeyPath<Mode, String>,
      isEnabled: WritableKeyPath<Mode, Bool>,
      readModes: @escaping @MainActor () -> [Mode],
      updateModes: @escaping @MainActor ([Mode]) -> Void,
    ) {
      self.id = id
      self.isEnabled = isEnabled
      self.readModes = readModes
      self.updateModes = updateModes
    }

    /// Reads and replaces the live state without suspending between the callbacks.
    public func run(modeID: String, commandName: String, action: ModeAction) throws -> String {
      var modes = readModes()
      guard let index = modes.firstIndex(where: { $0[keyPath: id] == modeID }) else {
        throw ModeError.unableToResolveMode
      }

      let enabled = switch action {
      case .enable: true
      case .disable: false
      case .toggle: !modes[index][keyPath: isEnabled]
      }
      modes[index][keyPath: isEnabled] = enabled
      updateModes(modes)
      let separator = action == .toggle ? ": " : " "
      return commandName + separator + (enabled ? "✅" : "⏸️")
    }
  }
}
