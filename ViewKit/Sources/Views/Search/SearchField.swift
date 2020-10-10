import Cocoa
import SwiftUI

class CocoaSearchField: NSSearchField, NSSearchFieldDelegate {
  @Binding var query: String

  init(_ query: Binding<String>) {
    self._query = query
    super.init(frame: .zero)
    self.delegate = self
    self.stringValue = query.wrappedValue
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: NSSearchFieldDelegate

  func controlTextDidChange(_ obj: Notification) {
    query = stringValue
  }
}

struct SearchField: NSViewRepresentable {
  @Binding var query: String

  func makeNSView(context: Context) -> some NSView {
    CocoaSearchField($query)
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
