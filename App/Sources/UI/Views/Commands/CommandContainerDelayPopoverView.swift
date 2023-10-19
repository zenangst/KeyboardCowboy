import Bonzai
import SwiftUI

struct CommandContainerDelayPopoverView: View {
  @State private var delayString: String
  @Binding private var metaData: CommandViewModel.MetaData
  @Binding private var isShown: Bool

  private let onChange: (Double) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>, 
       isShown: Binding<Bool>,
       onChange: @escaping (Double) -> Void) {
    if let delay = metaData.wrappedValue.delay {
      _delayString = .init(initialValue: String(Int(delay)))
    } else {
      _delayString = .init(initialValue: "")
    }
    _isShown = isShown
    _metaData = metaData
    self.onChange = onChange
  }

  var body: some View {
    HStack {
      TextField("Delay", text: $delayString) { isEditing in
        guard isShown else { return }
        if !isEditing {
          if let value = Double(self.delayString) {
            if value > 0 {
              metaData.delay = value
            } else {
              metaData.delay = nil
            }
            onChange(value)
          }
        }
      }
      .textFieldStyle(.regular(Color(.windowBackgroundColor)))

      Button(action: {
        onChange(0)
        metaData.delay = nil
        isShown = false
      }, label: {
        Image(systemName: "clear")
      })
      .buttonStyle(.zen(ZenStyleConfiguration(color: .systemRed, grayscaleEffect: .constant(true))))
    }
    .padding(16)
  }
}

struct CommandContainerDelayPopoverView_Previews: PreviewProvider {
  static let model = CommandViewModel.MetaData(
    id: UUID().uuidString,
    delay: 1.0,
    name: UUID().uuidString,
    namePlaceholder: UUID().uuidString,
    isEnabled: false,
    notification: false
  )

  static var previews: some View {
    CommandContainerDelayPopoverView(
      .constant(model),
      isShown: .constant(true),
      onChange: { _ in })
  }
}
