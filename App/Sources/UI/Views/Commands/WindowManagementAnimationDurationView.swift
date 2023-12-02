import Inject
import SwiftUI

struct WindowManagementAnimationDurationView: View {
  @ObserveInjection var inject
  @State private var animationDurationVisible: Bool = false
  @Binding private var windowCommand: CommandViewModel.Kind.WindowManagementModel
  private let onChange: (Double) -> Void

  init(windowCommand: Binding<CommandViewModel.Kind.WindowManagementModel>, onChange: @escaping (Double) -> Void) {
    _windowCommand = windowCommand
    self.onChange = onChange
  }

  var body: some View {
    Button {
      animationDurationVisible = true
    } label: {
      HStack {
        HStack(spacing: 4) {
          Image(systemName: "sparkles")
          if windowCommand.animationDuration > 0 {
            Text("\(Int(windowCommand.animationDuration * 1000)) milliseconds")
              .font(.caption)
          } else {
            Text("No animation")
              .font(.caption)
          }
        }
        Divider()
          .frame(height: 6)
        Image(systemName: "chevron.down")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 6, height: 6)
      }
    }
    .buttonStyle(.zen(.init(color: .systemGray)))
    .popover(isPresented: $animationDurationVisible, content: {
      WindowManagementAnimationPopoverView($windowCommand, isShown: $animationDurationVisible, onChange: {
        windowCommand.animationDuration = $0
        onChange($0)
      })
    })
    .enableInjection()
  }
}

struct WindowManagementAnimationDurationView_Previews: PreviewProvider {
  static let windowCommand = CommandViewModel.Kind.WindowManagementModel(id: UUID().uuidString, kind: .center, animationDuration: 0.375)
  static var previews: some View {
    WindowManagementAnimationDurationView(windowCommand: .constant(windowCommand)) { _ in }
      .frame(width: 200)
  }
}
