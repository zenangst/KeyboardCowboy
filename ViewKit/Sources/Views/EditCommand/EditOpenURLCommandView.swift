import SwiftUI
import ModelKit

struct EditOpenURLCommandView: View {
  @State var url: String = ""
  @Binding var command: OpenCommand

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open URL").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        HStack {
          Text("URL:")
          TextField("http://", text: Binding(get: {
            command.path
          }, set: {
            command = .init(id: command.id, path: $0)
          }))
        }
      }.padding()
    }
  }
}

struct EditOpenURLCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    EditOpenURLCommandView(
      command: .constant(OpenCommand.empty())
    )
  }
}
