import SwiftUI

struct MoveFocusToWindowIconView: View {
  enum Direction: CaseIterable {
    case previous
    case next
  }

  enum Scope: CaseIterable {
    case activeApplication
    case visibleWindows
    case allWindows
  }

  private let direction: Direction
  private let scope: Scope
  private let size: CGFloat

  init(direction: Direction, scope: Scope, size: CGFloat) {
    self.direction = direction
    self.scope = scope
    self.size = size
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(baseColor(for: scope))
      .overlay { MoveFocusToWindowIconBackgroundView() }
      .overlay { iconBorder(size) }
      .overlay(content: {
        ZStack(alignment: .leading) {
          stageManager()
            .opacity(scope == .allWindows ? 1 : 0)
          windows()
            .offset(
              x: windowsXOffset(for: scope),
              y: windowsYOffset(for: scope),
            )
            .frame(maxWidth: .infinity)
        }
      })
      .overlay(alignment: .bottomTrailing) {
        Image(systemName: "app")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size * 0.1)
          .padding(size * 0.055)
          .font(Font.system(size: size * 0.2, weight: .bold, design: .rounded))
          .background(
            LinearGradient(stops: [
              .init(color: Color(nsColor: .controlAccentColor.withSystemEffect(.rollover)), location: 0),
              .init(color: Color(nsColor: .controlAccentColor), location: 0.8),
              .init(color: Color(nsColor: .controlAccentColor.withSystemEffect(.disabled)), location: 1.0),
            ], startPoint: .top, endPoint: .bottomTrailing)
              .cornerRadius(size * 0.125),
          )
          .padding([.bottom, .trailing], size * 0.055)
          .opacity(scope == .activeApplication ? 1 : 0)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }

  func windowsXOffset(for scope: Scope) -> CGFloat {
    switch scope {
    case .activeApplication, .visibleWindows: 0
    case .allWindows: size * 0.075
    }
  }

  func windowsYOffset(for scope: Scope) -> CGFloat {
    switch scope {
    case .activeApplication: -size * 0.075
    case .visibleWindows, .allWindows: 0
    }
  }

  private func baseColor(for scope: Scope) -> Color {
    switch scope {
    case .activeApplication:
      Color(direction == .next ? .systemBlue : .systemBlue.withSystemEffect(.disabled))
    case .visibleWindows:
      Color(direction == .next ? .systemGreen : .systemGreen.withSystemEffect(.disabled))
    case .allWindows:
      Color(direction == .next ? .systemOrange : .systemOrange.withSystemEffect(.disabled))
    }
  }

  private func stageManager() -> some View {
    VStack(spacing: size * 0.0_340) {
      MoveFocusToWindowShapeView(width: size * 0.15, height: size * 0.15)
      MoveFocusToWindowShapeView(width: size * 0.15, height: size * 0.15)
      MoveFocusToWindowShapeView(width: size * 0.15, height: size * 0.15)
      MoveFocusToWindowShapeView(width: size * 0.15, height: size * 0.15)
    }
    .grayscale(1)
    .opacity(0.25)
    .rotation3DEffect(.degrees(45), axis: (x: 0.0, y: 1.0, z: 0.0))
  }

  private func windows() -> some View {
    HStack(spacing: size * 0.0_340) {
      let unfocusedSize = CGSize(width: size * 0.35, height: size * 0.45)
      let unfocusedOpacity = 0.6
      let focusedSize = CGSize(width: size * 0.45, height: size * 0.6)
      let focusedOpacity = 1.0
      MoveFocusToWindowShapeView(width: direction == .next ? unfocusedSize.width : focusedSize.width,
                                 height: direction == .next ? unfocusedSize.height : focusedSize.height)
        .opacity(direction == .next ? unfocusedOpacity : focusedOpacity)
        .grayscale(direction == .next ? 1 : 0)
      MoveFocusToWindowShapeView(width: direction == .next ? focusedSize.width : unfocusedSize.width,
                                 height: direction == .next ? focusedSize.height : unfocusedSize.height)
        .opacity(direction == .next ? focusedOpacity : unfocusedOpacity)
        .grayscale(direction == .next ? 0 : 1)
        .shadow(radius: 4, y: 2)
    }
  }
}

private struct MoveFocusToWindowShapeView: View {
  private let width: CGFloat
  private let height: CGFloat

  init(width: CGFloat, height: CGFloat) {
    self.width = width
    self.height = height
  }

  var body: some View {
    Rectangle()
      .frame(width: width, height: height)
      .overlay { iconOverlay().opacity(0.5) }
      .overlay { iconBorder(width * 0.7) }
      .overlay(alignment: .topLeading) {
        HStack(alignment: .top, spacing: 0) {
          HStack(alignment: .top, spacing: width * 0.0_240) {
            Circle()
              .fill(Color(.systemRed))
            Circle()
              .fill(Color(.systemYellow))
            Circle()
              .fill(Color(.systemGreen))
            Divider()
              .frame(width: 1)
          }
          .frame(width: width * 0.3)
          .padding([.leading, .top], width * 0.0675)
          Rectangle()
            .fill(.white)
            .frame(maxWidth: .infinity)
            .overlay { iconOverlay().opacity(0.5) }
        }
      }
      .iconShape(width * 0.7)
  }
}

private struct MoveFocusToWindowIconBackgroundView: View {
  var body: some View {
    AngularGradient(stops: [
      .init(color: Color.clear, location: 0.0),
      .init(color: Color.white.opacity(0.2), location: 0.2),
      .init(color: Color.clear, location: 1.0),
    ], center: .bottomLeading)

    LinearGradient(stops: [
      .init(color: Color.white.opacity(0.2), location: 0),
      .init(color: Color.clear, location: 0.3),
    ], startPoint: .top, endPoint: .bottom)

    LinearGradient(stops: [
      .init(color: Color.clear, location: 0.8),
      .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
    ], startPoint: .top, endPoint: .bottom)
  }
}

#Preview {
  VStack {
    ForEach(MoveFocusToWindowIconView.Scope.allCases, id: \.self) { scope in
      ForEach(MoveFocusToWindowIconView.Direction.allCases, id: \.self) { direction in
        IconPreview { MoveFocusToWindowIconView(direction: direction, scope: scope, size: $0) }
      }
    }
  }
  .padding()
}
