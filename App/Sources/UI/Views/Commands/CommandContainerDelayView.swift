import Bonzai
import Inject
import SwiftUI

struct CommandContainerDelayView: View {
  @ObserveInjection var inject
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
    Group {
      switch execution {
      case .concurrent:
        EmptyView()
      case .serial:
        Button {
          delayOverlay = true
        } label: {
          HStack {
            HStack(spacing: 4) {
              Image(systemName: "hourglass")
              if let delay = metaData.delay {
                Text("\(Int(delay)) milliseconds")
                  .font(.caption)
              } else {
                Text("No delay")
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
        .buttonStyle(.zen(ZenStyleConfiguration(color: .systemGray)))
        .popover(isPresented: $delayOverlay, content: {
          CommandContainerDelayPopoverView($metaData, isShown: $delayOverlay, onChange: onChange)
        })
      }
    }
  }
}

struct CommandContainerDelayView_Previews: PreviewProvider {
  static let model = CommandViewModel.MetaData(
    id: UUID().uuidString,
    delay: 1.0,
    name: UUID().uuidString,
    namePlaceholder: UUID().uuidString,
    isEnabled: false,
    notification: false
  )

  static var previews: some View {
    CommandContainerDelayView(
      metaData: .constant(model),
      execution: .serial,
      onChange: { _ in }
    )
    .padding()
  }
}
