import SwiftUI

struct CommandContainerDelayView: View {
  @State private var delayOverlay: Bool = false
  @Binding private var metaData: CommandViewModel.MetaData
  private let execution: DetailViewModel.Execution
  private let onChange: (Double) -> Void

  init(metaData: Binding<CommandViewModel.MetaData>,
       execution: DetailViewModel.Execution,
       onChange: @escaping (Double) -> Void) {
    _metaData = metaData
    self.execution = execution
    self.onChange = onChange
  }

  var body: some View {
    switch execution {
    case .concurrent:
      EmptyView()
    case .serial:
      Button {
        delayOverlay = true
      } label: {
        HStack {
          if let delay = metaData.delay {
            Text("\(Int(delay)) milliseconds")
              .font(.caption)
          } else {
            Text("No delay")
              .font(.caption)
          }
          Divider()
            .frame(height: 6)
          Image(systemName: "chevron.down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 6, height: 6)
        }
      }
      .buttonStyle(AppButtonStyle(.init(nsColor: .systemGray)))
      .popover(isPresented: $delayOverlay, content: {
        CommandContainerDelayPopoverView($metaData, onChange: onChange)
      })
    }
  }
}
