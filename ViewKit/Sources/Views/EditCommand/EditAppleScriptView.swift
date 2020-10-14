import SwiftUI
import ModelKit

struct EditAppleScriptView: View {
  @Binding var command: ScriptCommand
  @ObservedObject var openPanelController: OpenPanelController

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Apple script").font(.title)
        Spacer()
      }.padding()
      Divider()
      VStack {
        HStack {
          Text("Path:")
          TextField("file://", text: Binding(get: {
            if case .appleScript(let source, _) = command,
               case .path(let value) = source {
              return value
            }
            return ""
          }, set: {
            command = ScriptCommand.appleScript(.path($0), command.id)
          }))
        }
        HStack {
          Spacer()
          Button("Browse", action: {
            openPanelController.perform(.selectFile(type: "scpt", handler: {
              command = ScriptCommand.appleScript(.path($0), command.id)
            }))
          })
        }
      }.padding()
    }
  }
}

struct EditAppleScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
      EditAppleScriptView(
        command: .constant(ScriptCommand.empty(.appleScript)),
        openPanelController: OpenPanelPreviewController().erase())
    }
}

private final class OpenPanelPreviewController: ViewController {
  let state = ""
  func perform(_ action: OpenPanelAction) {}
}
