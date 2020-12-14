import SwiftUI

struct ConfirmViewConfig {
  let text: String

  let confirmText: String
  let confirmAction: () -> Void

  let cancelText: String
  let cancelAction: () -> Void
}

struct ConfirmView: View {
  let config: ConfirmViewConfig

  var body: some View {
    VStack(spacing: 0) {
      Text(config.text).padding()
      Divider()
      HStack {
        Button(config.cancelText, action: config.cancelAction).keyboardShortcut(.cancelAction)
        Button(config.confirmText, action: config.confirmAction).keyboardShortcut(.defaultAction)
      }.padding()
    }
  }
}
