public extension Command {
  protocol MetaDataProviding: Identifiable, Codable, Hashable, Sendable {
    var meta: Command.Metadata { get set }
  }
}

public extension Command.MetaDataProviding {
  var id: String {
    get { meta.id }
    set { meta.id = newValue }
  }

  var name: String {
    get { meta.name }
    set { meta.name = newValue }
  }

  var notification: Command.Notification? {
    get { meta.notification }
    set { meta.notification = newValue }
  }

  var isEnabled: Bool {
    get { meta.isEnabled }
    set { meta.isEnabled = newValue }
  }

  var delay: Double? {
    get { meta.delay }
    set { meta.delay = newValue }
  }

  var variableName: String? {
    get { meta.variableName }
    set {
      if newValue == nil || newValue?.isEmpty == true {
        meta.variableName = nil
      } else {
        meta.variableName = newValue
      }
    }
  }
}
