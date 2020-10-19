import SwiftUI

struct HelperView: View {
  let text: String
  let contentView: AnyView

  @ViewBuilder
  var body: some View {
    VStack {
      contentView
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
    HelperView(text: "Additional helper text",
               contentView: Text("Instructions").erase())
  }
}
