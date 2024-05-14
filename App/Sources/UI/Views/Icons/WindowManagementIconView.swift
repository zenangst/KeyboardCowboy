import Bonzai
import Inject
import SwiftUI

struct WindowManagementIconView: View {
  let size: CGFloat

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack {
        WindowManagementIconWindowControlsView(size: size)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(WindowManagementIconBackgroundView())

      let rectangleWidth = size * 0.0125

      Rectangle()
        .fill(Color(.systemGray))
        .frame(width: rectangleWidth)
      Rectangle()
        .fill(Color.white)
        .frame(width: rectangleWidth)

      WindowManagementIconWindowView(size: size)
        .frame(width: size * 0.182)
    }
    .overlay { iconBorder(size) }
    .background()
    .compositingGroup()
    .iconShape(size)
    .frame(width: size, height: size)
    .fixedSize()
  }
}

struct WindowManagementIconBackgroundView: View {
  var body: some View {
    Rectangle()
      .fill(Color(nsColor: NSColor(red:0.94, green:0.71, blue:0.51, alpha:1.00)))
      .overlay {
        // Yellow
        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.1),
          .init(color: Color(nsColor: NSColor(red:0.95, green:0.70, blue:0.25, alpha:1.00)), location: 0.2),
          .init(color: Color(nsColor: NSColor(red:0.94, green:0.71, blue:0.51, alpha:1.00)), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)

        // Blue
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(nsColor: NSColor(red:0.29, green:0.64, blue:0.87, alpha:1.00)),
                  location: 0.0),
            .init(color: .clear, location: 0.60),
          ]),
          startPoint: .topTrailing,
          endPoint: .bottomLeading)

        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(.systemPink).opacity(0.4), location: 0.0),
            .init(color: .clear, location: 1.0),
          ]),
          startPoint: .bottomLeading,
          endPoint: .leading
        )

        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(.systemRed), location: 0.2),
            .init(color: .clear, location: 0.5),
          ]),
          startPoint: .bottomLeading,
          endPoint: .trailing
        )

        LinearGradient(
          gradient: Gradient(
            stops:
              [
                .init(color: .clear, location: 0.0),
                .init(color: Color(nsColor: NSColor(red:0.91, green:0.20, blue:0.45, alpha:1.00)), location: 0.25),
                .init(color: .clear, location: 0.6),
              ]),
          startPoint: .bottomLeading,
          endPoint: .trailing
        )

        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(nsColor: NSColor(red:0.44, green:0.25, blue:0.51, alpha:1.00)), location: 0),
            .init(color: .clear, location: 0.3),
          ]),
          startPoint: .bottomLeading,
          endPoint: .topTrailing
        )
      }
      .blur(radius: 1)
      .compositingGroup()
      .drawingGroup()
  }
}

private struct WindowManagementIconWindowControlsView: View {
  let size: CGFloat
  var body: some View {
    HStack(spacing: size * 0.0_55) {
      let circleHeight = size * 0.15

      Circle()
        .fill(
          LinearGradient(stops: [
            .init(color: Color(nsColor: NSColor(red:0.88, green:0.19, blue:0.14, alpha:1.00)), location: 0.1),
            .init(color: Color(.systemRed), location: 1)
          ],
                         startPoint: .top,
                         endPoint: .bottom)
        )
        .frame(height: circleHeight)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:1.00, green:0.98, blue:0.37, alpha:1.00)),
            Color(.systemYellow)
          ], startPoint: .top, endPoint: .bottom)
        )
        .frame(height: circleHeight)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:0.44, green:0.94, blue:0.39, alpha:1.00)),
            Color(.systemGreen)
          ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .frame(height: circleHeight)
    }
    .compositingGroup()
    .shadow(radius: size * 0.0_05, y: 1)
    .fontWeight(.bold)
    .padding([.top, .leading, .trailing], size * 0.0_5)
    .frame(height: size * 0.25)
    .drawingGroup()
  }
}

private struct WindowManagementIconWindowView: View {
  let size: CGFloat
  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .frame(height: size * 0.30)
      Rectangle()
        .fill(Color(.white))
        .frame(height: size * 0.0125)
      Rectangle()
        .fill(Color(.systemGray))
        .frame(height: size * 0.0125)
      Rectangle()
        .fill(Color(.systemGray).opacity(0.4))
    }
    .background(Color(.white))
  }
}

struct WindowManagementIconView_Previews: PreviewProvider {
  @State static var stacked: Bool = true
  static var previews: some View {
    HStack(alignment: .top, spacing: 8) {
      WindowManagementIconView(size: 192)
      VStack(alignment: .leading, spacing: 8) {
        WindowManagementIconView(size: 128)
        HStack(alignment: .top, spacing: 8) {
          WindowManagementIconView(size: 64)
          WindowManagementIconView(size: 32)
          WindowManagementIconView(size: 16)
        }
      }
    }
    .padding()
  }
}
