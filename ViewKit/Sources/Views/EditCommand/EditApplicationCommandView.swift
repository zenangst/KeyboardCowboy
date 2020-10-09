import SwiftUI

public enum OpenPanelAction {
  case selectFile(type: String?, handler: (String) -> Void)
  case selectFolder(handler: (String) -> Void)
}

struct EditApplicationCommandView: View {
  @State private var selection: Int = 0
  @Binding var commandViewModel: CommandViewModel
  var installedApplications: [ApplicationViewModel]

  init(commandViewModel: Binding<CommandViewModel>,
       installedApplications: [ApplicationViewModel]) {
    self._commandViewModel = commandViewModel
    self.installedApplications = installedApplications
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Open application").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        Picker("Application: ", selection: Binding(get: {
          selection
        }, set: {
          selection = $0
          commandViewModel.kind = .application(installedApplications[$0])
        })) {
          ForEach(0..<installedApplications.count) { index in
            Text(installedApplications[index].name).tag(index)
          }
        }
      }.onAppear {
        if case .application(let viewModel) = commandViewModel.kind,
           let index = installedApplications.firstIndex(where: { viewModel.bundleIdentifier == $0.bundleIdentifier }) {
          selection = index
        } else if !installedApplications.isEmpty {
          commandViewModel.kind = .application(installedApplications[0])
        }
      }.padding()
    }
  }
}

struct EditApplicationCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let models = ModelFactory().installedApplications()
    return EditApplicationCommandView(
      commandViewModel: .constant(.init(id: "",
                                        name: "",
                                        kind: .application(ApplicationViewModel.finder()))),
      installedApplications: models)
  }
}
