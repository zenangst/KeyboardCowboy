package extension HostOpen {
  enum Event: String, Sendable {
    case tabSearchStarted = "tab search started"
    case tabSearchNoMatch = "tab search found no matching tab"
    case tabSearchAutomationDenied = "tab search was denied Automation permission"
    case tabSearchFailed = "tab search script failed"
    case browserSucceeded = "browser route succeeded"
    case browserFailed = "browser route failed"
    case genericOpenStarted = "generic open started"
  }
}
