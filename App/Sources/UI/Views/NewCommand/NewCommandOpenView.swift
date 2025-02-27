import Apps
import Bonzai
import Inject
import SwiftUI

struct NewCommandOpenView: View {
  @ObserveInjection var inject
  enum Focus {
    case path
  }
  private let wikiUrl = URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki/Commands#open-commands")!

  @EnvironmentObject var applicationStore: ApplicationStore
  @EnvironmentObject var openPanel: OpenPanelController

  @FocusState var focus: Focus?

  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandValidation
  @State private var application: Application?
  @State private var path: String = "~/"

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandValidation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        ZenLabel("Open File or Folder:")
        Spacer()
        Button(action: { NSWorkspace.shared.open(wikiUrl) },
               label: { Image(systemName: "questionmark.circle.fill") })
      }

      HStack(spacing: 0) {
        ZStack(alignment: .bottomTrailing) {
          Image(nsImage: NSWorkspace().icon(forFile: (path as NSString).expandingTildeInPath))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24)

          if let application {
            Image(nsImage: NSWorkspace().icon(forFile: application.path))
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16)
              .shadow(radius: 3)
          }
        }

        TextField("Path", text: $path)
          .textFieldStyle { textField in
            textField.font = .title
          }
          .focused($focus, equals: .path)
        Button("Browse", action: {
          openPanel.perform(.selectFile(types: [], handler: { path in
            self.path = path
          }))
        })
      }
      .roundedSubStyle()

      ZenDivider()

      HStack(spacing: 32) {
        Text("With Application: ")
        Menu(content: {
          ForEach(applicationStore.applications) { app in
            Button(action: {
              application = app
              updatePayload()
            }, label: {
              Text(app.displayName)
            })
          }
        }, label: {
          if let application {
            Text(application.displayName)
          } else {
            Text("Default application")
          }
        })
      }
    }
    .onAppear {
      validation = .valid
      updatePayload()
      focus = .path
    }
    .onChange(of: self.path, perform: { newValue in
      updatePayload()
    })
    .enableInjection()
  }

  private func updatePayload() {
    payload = .open(path: path, application: application)
  }
}

struct NewCommandOpenView_Previews: PreviewProvider {
  static var previews: some View {
    NewCommandView(
      workflowId: UUID().uuidString,
      commandId: nil,
      title: "New command",
      selection: .open,
      payload: .placeholder,
      onDismiss: {},
      onSave: { _, _ in })
    .designTime()
  }
}
