import SwiftUI

struct HelperView<Content: View>: View {
  let content: () -> Content
  let text: String

  init(text: String, @ViewBuilder _ content: @escaping () -> Content) {
    self.content = content
    self.text = text
  }

  var body: some View {
    VStack {
      content()
      Divider().frame(width: 25)
      Text(text)
        .font(.caption)
        .padding(.bottom)
    }
  }
}

struct HelperView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    HelperView(text: "Additional helper text", { Text("Instructions") })
  }
}
