import SwiftUI

struct WindowManagementAnimationPopoverView: View {
  @State private var animationDuration: String
  @Binding private var windowCommand: CommandViewModel.Kind.WindowManagementModel

  private let onChange: (Double) -> Void

  init(_ windowCommand: Binding<CommandViewModel.Kind.WindowManagementModel>,
       onChange: @escaping (Double) -> Void) {
    _windowCommand = windowCommand
    _animationDuration = .init(initialValue: String(windowCommand.wrappedValue.animationDuration))
    self.onChange = onChange
  }

  var body: some View {
    HStack {
      TextField("Animation duration", text: $animationDuration) { isEditing in
        if !isEditing {
          if let value = Double(self.animationDuration) {
            if value > 0 {
              windowCommand.animationDuration = value
            } else {
              windowCommand.animationDuration = 0
            }
            onChange(value)
          }
        }
      }
    }
    .padding(16)
  }
}

