import SwiftUI

struct CommandContainerDelayPopoverView: View {
  @State private var delayString: String
  @Binding private var metaData: CommandViewModel.MetaData

  private let onChange: (Double) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>, 
       onChange: @escaping (Double) -> Void) {
    if let delay = metaData.wrappedValue.delay {
      _delayString = .init(initialValue: String(Int(delay)))
    } else {
      _delayString = .init(initialValue: "")
    }
    _metaData = metaData
    self.onChange = onChange
  }

  var body: some View {
    HStack {
      TextField("Delay", text: $delayString) { isEditing in
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
    }
    .padding(16)
  }
}

