import Cocoa
import SwiftUI

class SearchFieldCoordinator: NSObject, NSSearchFieldDelegate {
  @Binding var query: String
  let view: NSSearchField

  init(_ query: Binding<String>) {
    self._query = query
    self.view = NSSearchField()
    super.init()
    self.view.delegate = self
    self.view.stringValue = query.wrappedValue
  }

  // MARK: NSSearchFieldDelegate

  func controlTextDidChange(_ obj: Notification) {
    query = view.stringValue
  }
}

struct SearchField: NSViewRepresentable {
  @Binding var query: String

  func makeCoordinator() -> SearchFieldCoordinator {
    SearchFieldCoordinator($query)
  }

  func makeNSView(context: Context) -> some NSView {
    context.coordinator.view
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {}
}

struct SearchField_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      SearchField(query: .constant(""))
      SearchField(query: .constant("Search string"))
    }
  }
}
