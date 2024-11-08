import Inject
import SwiftUI

struct SingleDetailBackgroundView: View {
  @ObserveInjection var inject
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject private var commandsPublisher: CommandsPublisher
  @EnvironmentObject private var triggerPublisher: TriggerPublisher

  var body: some View {
    let shouldShowCommandList = triggerPublisher.data != .empty ||
                               !commandsPublisher.data.commands.isEmpty

    Rectangle()
      .fill(
        LinearGradient(stops: gradientStops(), startPoint: .top, endPoint: .bottom)
      )
      .mask(
        Canvas(opaque: true, rendersAsynchronously: true) { context, size in
          context.fill(
            Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                    height: size.height - 16))),
            with: .color(Color(.black))
          )

          context.fill(Path { path in
            path.move(to: CGPoint(x: size.width / 2, y: size.height - 16))

            path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 16))
            path.addLine(to: CGPoint(x: size.width / 2,
                                     y: shouldShowCommandList ? size.height - 6 : size.height - 16))
            path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 16))
          }, with: .color(Color(.black)))
        }
      )
      .shadow(color: shadowColor(), radius: 1, y: 1)
      .enableInjection()
  }

  func gradientStops() -> [Gradient.Stop] {
    colorScheme == .dark
    ?
    [
      .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.3, of: .white)!), location: 0.0),
      .init(color: Color(nsColor: .windowBackgroundColor), location: 0.01),
      .init(color: Color(nsColor: .windowBackgroundColor), location: 1.0),
    ]
    :
    [
      .init(color: Color(nsColor: .systemGray), location: 0.0),
      .init(color: Color(nsColor: .white), location: 0.01),
      .init(color: Color(nsColor: .windowBackgroundColor), location: 1.0),
    ]
  }

  func shadowColor() -> Color {
    colorScheme == .dark
    ? Color(.sRGBLinear, white: 0, opacity: 0.33)
    : Color(.sRGBLinear, white: 0, opacity: 0.15)
  }
}
