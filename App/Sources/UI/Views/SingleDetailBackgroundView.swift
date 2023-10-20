import SwiftUI

struct SingleDetailBackgroundView: View {
  private var commandsPublisher: CommandsPublisher
  private var triggerPublisher: TriggerPublisher

  init(commandsPublisher: CommandsPublisher, triggerPublisher: TriggerPublisher) {
    self.commandsPublisher = commandsPublisher
    self.triggerPublisher = triggerPublisher
  }

  var body: some View {
    let shouldShowCommandList = triggerPublisher.data != .empty ||
    !commandsPublisher.data.commands.isEmpty

    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .white)!), location: 0.0),
          .init(color: Color(nsColor: .windowBackgroundColor), location: 0.01),
          .init(color: Color(nsColor: .windowBackgroundColor), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .mask(
        Canvas(rendersAsynchronously: true) { context, size in
          context.fill(
            Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                    height: size.height - 12))),
            with: .color(Color(.black))
          )

          if shouldShowCommandList {
            context.fill(Path { path in
              path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
              path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 12))
            }, with: .color(Color(.black)))
          }
        }
      )
      .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2),
                 value: shouldShowCommandList)
      .compositingGroup()
      .shadow(color: Color.white.opacity(0.2), radius: 0, y: 1)
      .shadow(radius: 2, y: 2)
  }
}
