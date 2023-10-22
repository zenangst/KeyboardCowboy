import Inject
import SwiftUI

struct SingleDetailBackgroundView: View {
  @ObserveInjection var inject
  @EnvironmentObject private var commandsPublisher: CommandsPublisher
  @EnvironmentObject private var triggerPublisher: TriggerPublisher

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
        Canvas(opaque: true, rendersAsynchronously: true) { context, size in
          context.fill(
            Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                    height: size.height - 12))),
            with: .color(Color(.black))
          )

          context.fill(Path { path in
            path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))

            path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
            path.addLine(to: CGPoint(x: size.width / 2,
                                     y: shouldShowCommandList ? size.height - 2 : size.height - 12))
            path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))

          }, with: .color(Color(.black)))
        }
      )
      .shadow(color: Color.white.opacity(0.2), radius: 0, y: 1)
      .shadow(radius: 2, y: 2)
      .enableInjection()
  }
}
