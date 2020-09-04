import Foundation

struct ScriptCommand {
  let kind: Kind

  enum Kind {
    case appleScript(Source)
    case shell(Source)
  }

  enum Source {
    case path(URL)
    case inline(String)
  }
}
