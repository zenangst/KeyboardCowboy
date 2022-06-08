import Carbon
import Cocoa
import SwiftUI

struct SearchField: NSViewRepresentable {
  @Binding var query: String

  func makeCoordinator() -> SearchFieldCoordinator {
    SearchFieldCoordinator($query)
  }

  func makeNSView(context: Context) -> some NSSearchField {
    context.coordinator.view
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {}
}

final class SearchFieldCoordinator: NSObject, NSSearchFieldDelegate {
  @Binding var query: String
  let view: NSSearchField

  init(_ query: Binding<String>) {
    self._query = query
    let searchField = NSSearchField()
    self.view = searchField
    super.init()
    searchField.delegate = self
    searchField.stringValue = query.wrappedValue
  }

  // MARK: NSSearchFieldDelegate

  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if commandSelector == #selector(NSControl.moveUp(_:)) {
      return true
    } else if commandSelector == #selector(NSControl.moveDown(_:)) {
      if let firstMatch = ResponderChain.shared.responders.first(where: { $0.id.starts(with: "search-") }) {
        ResponderChain.shared.makeFirstResponder(firstMatch)
      }
      return true
    }
    return false
  }

  func controlTextDidChange(_ obj: Notification) {
    query = view.stringValue
  }
}


struct SearchField_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SearchField(query: .constant(""))
      SearchField(query: .constant("Search string"))
    }
  }
}
