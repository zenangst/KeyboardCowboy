import Foundation

/// An application command is a container that is used for
/// launching or activing applications.
public struct ApplicationCommand: Codable, Hashable {
  public var application: Application
}
