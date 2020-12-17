import SwiftUI
import ModelKit

struct KeyboardRecorderView: View {
  @Binding var keyboardShortcut: ModelKit.KeyboardShortcut?
  @State var failureMessage: String?
  @State var isShowingError: Bool = false

  var body: some View {
    ZStack {
      Recorder(keyboardShortcut: $keyboardShortcut,
               validationError: Binding<String?>(
                get: { failureMessage },
                set: {
                  failureMessage = $0
                  isShowingError = $0?.isEmpty == false
                }))
        .popover(isPresented: $isShowingError,
                 attachmentAnchor: .point(UnitPoint.bottom),
                 arrowEdge: .bottom,
                 content: {
                  Text("\(failureMessage ?? "")")
                    .padding([.leading, .trailing, .bottom], 10)
                    .padding(.top, 10)

        })
    }
  }
}
// MARK: - Previews

struct KeyboardRecorderView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      KeyboardRecorderView(keyboardShortcut: .constant(ModelFactory().keyboardShortcuts().first!))

      KeyboardRecorderView(keyboardShortcut: .constant(ModelFactory().keyboardShortcuts().first!),
                           failureMessage: "X")
    }.frame(width: 320)
  }
}
