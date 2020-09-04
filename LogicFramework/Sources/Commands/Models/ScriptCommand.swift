import Foundation

struct ScriptCommand {
  let kind: Kind
  let path: String

  enum Kind {
    case appleScript(Source)
    case shell(Source)
  }

  enum Source {
    case path(URL)
    case inline(String)
  }
}
