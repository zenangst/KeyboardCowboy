import SwiftUI

struct EditOpenURLCommandView: View {
  @State var url: String = ""
  @Binding var commandViewModel: CommandViewModel

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
            if case .openUrl(let viewModel) = commandViewModel.kind {
              return viewModel.url.absoluteString
            }
            return ""
          }, set: {
            if let url = URL(string: $0) {
              commandViewModel.kind = .openUrl(OpenURLViewModel(url: url))
            }
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
      commandViewModel: .constant(
        CommandViewModel(name: "", kind: .shellScript(ShellScriptViewModel.empty()))
      )
    )
  }
}
