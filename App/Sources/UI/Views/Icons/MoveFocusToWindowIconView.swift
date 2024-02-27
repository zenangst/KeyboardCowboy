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
  let direction: Direction
  let scope: Scope
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(baseColor(for: scope))
      .overlay { background() }
      .overlay { iconBorder(size) }
      .overlay(content: {
        HStack(spacing: size * 0.0_140) {
          if scope == .allWindows {
            stageManager()
          }
          windows()
            .offset(y: scope == .activeApplication ? -size * 0.075 : 0)
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
            .cornerRadius(size * 0.125)
          )
          .padding([.bottom, .trailing], size * 0.055)
          .opacity( scope == .activeApplication ? 1 : 0)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }

  private func baseColor(for scope: Scope) -> Color {
    switch scope {
    case .activeApplication:
      if direction == .next {
        Color(.systemBlue)
      } else {
        Color(nsColor: .systemBlue.withSystemEffect(.disabled))
      }
    case .visibleWindows:
      if direction == .next {
        Color(.systemGreen)
      } else {
        Color(.systemGreen.withSystemEffect(.disabled))
      }
    case .allWindows:
      if direction == .next {
        Color(.systemOrange)
      } else {
        Color(nsColor: .systemOrange.withSystemEffect(.disabled))
      }
    }
  }

  @ViewBuilder
  private func background() -> some View {
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

  private func stageManager() -> some View {
    VStack(spacing: size * 0.0_340) {
      windowShape(width: size * 0.15, height: size * 0.15)
      windowShape(width: size * 0.15, height: size * 0.15)
      windowShape(width: size * 0.15, height: size * 0.15)
      windowShape(width: size * 0.15, height: size * 0.15)
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
      windowShape(width: direction == .next ? unfocusedSize.width : focusedSize.width,
                  height: direction == .next ? unfocusedSize.height : focusedSize.height)
      .opacity(direction == .next ? unfocusedOpacity : focusedOpacity)
      .grayscale(direction == .next ? 1 : 0)
      windowShape(width: direction == .next ? focusedSize.width : unfocusedSize.width,
                  height: direction == .next ? focusedSize.height : unfocusedSize.height)
      .opacity(direction == .next ? focusedOpacity : unfocusedOpacity)
      .grayscale(direction == .next ? 0 : 1)
      .shadow(radius: 4, y: 2)
    }
  }

  private func windowShape(width: CGFloat, height: CGFloat) -> some View {
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

#Preview {
  VStack {
    ForEach(MoveFocusToWindowIconView.Scope.allCases, id: \.self) { scope in
    ForEach(MoveFocusToWindowIconView.Direction.allCases, id: \.self) { direction in
        HStack(alignment: .top, spacing: 8) {
          MoveFocusToWindowIconView(direction: direction, scope: scope, size: 192)
          VStack(alignment: .leading, spacing: 8) {
            MoveFocusToWindowIconView(direction: direction, scope: scope, size: 128)
            HStack(alignment: .top, spacing: 8) {
              MoveFocusToWindowIconView(direction: direction, scope: scope, size: 64)
              MoveFocusToWindowIconView(direction: direction, scope: scope, size: 32)
              MoveFocusToWindowIconView(direction: direction, scope: scope, size: 16)
            }
          }
        }
          .padding()
      }
    }
  }
  .padding()
}
