import Foundation

/// A `Command` is an action that lives inside a `Workflow`
///
/// - Examples: Launching an application, running a script
///             opening a file or folder.
struct Command: Identifiable, Hashable {
  let id: String = UUID().uuidString
  var name: String
}
