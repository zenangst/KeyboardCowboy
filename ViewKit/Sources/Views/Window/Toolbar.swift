import Cocoa

public class Toolbar: NSToolbar, NSToolbarDelegate {
  static let updates = NSToolbarItem.Identifier("Updates")
  static let support = NSToolbarItem.Identifier("Support")
  static let reportIssue = NSToolbarItem.Identifier("Issue")

  public override init(identifier: NSToolbar.Identifier) {
    super.init(identifier: identifier)
    delegate = self
  }

  public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    []
  }

  public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [
      NSToolbarItem.Identifier.space,
      NSToolbarItem.Identifier.flexibleSpace,
      Self.support,
      Self.updates,
      Self.reportIssue,
      NSToolbarItem.Identifier.separator
    ]
  }

  public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                      willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    switch itemIdentifier {
    case .space:
      return NSToolbarItem(itemIdentifier: .space)
    case .separator:
      return NSToolbarItem(itemIdentifier: .separator)
    case .flexibleSpace:
      return NSToolbarItem(itemIdentifier: .flexibleSpace)
    default:
      if itemIdentifier == Self.updates {
        return UpdatesToolbarItem(itemIdentifier: Self.updates)
      }
      if itemIdentifier == Self.support {
        return SupportToolbarItem(itemIdentifier: Self.support)
      }
      if itemIdentifier == Self.reportIssue {
        return ReportIssueToolbarItem(itemIdentifier: Self.reportIssue)
      }
    }
    return nil
  }
}

class ReportIssueToolbarItem: NSToolbarItem {
  var button = NSButton(title: "+", target: nil, action: nil)

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)
    view = button
    button.bezelStyle = .recessed
    button.title = "Report issue"
    button.alignment = .center
  }
}

class SupportToolbarItem: NSToolbarItem {
  var button = NSButton(title: "+", target: nil, action: nil)

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)
    view = button
    button.bezelStyle = .recessed
    button.title = "Support"
    button.alignment = .center
  }
}

class UpdatesToolbarItem: NSToolbarItem {
  var button = NSButton(title: "+", target: nil, action: nil)

  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)
    view = button
    button.bezelStyle = .recessed
    button.title = "Updates"
    button.alignment = .center
  }
}
