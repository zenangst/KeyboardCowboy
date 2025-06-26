import Bonzai
import SwiftUI

struct KeyboardCleanerIcon: View {
  @State var isAnimating: Bool = false
  private var animated: Bool
  private let size: CGFloat

  init(size: CGFloat = 20, animated: Bool = true) {
    self.size = size
    self.animated = animated
  }

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemGray.blended(withFraction: 0.25, of: .black)!), location: 0.0),
          .init(color: Color(.systemGray.blended(withFraction: 0.5, of: .black)!), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .frame(width: size, height: size)
      .fixedSize()
      .overlay {
        VStack(spacing: size * 0.02) {
          HStack(spacing: size * 0.02) {
            KeyboardIconView("Q", size: size * 0.275)
            KeyboardIconView("W", size: size * 0.275)
            KeyboardIconView("E", size: size * 0.275)
          }
          HStack(spacing: size * 0.02) {
            KeyboardIconView("A", size: size * 0.275)
            KeyboardIconView("S", size: size * 0.275)
            KeyboardIconView("D", size: size * 0.275)
          }

          HStack(spacing: size * 0.02) {
            KeyboardIconView("Z", size: size * 0.275)
            KeyboardIconView("X", size: size * 0.275)
            KeyboardIconView("C", size: size * 0.275)
          }
        }
      }
      .iconShape(size)
      .overlay {
        BubbleSystemView(isAnimating: $isAnimating, animated: animated, size: size)
      }
      .onAppear {
        if animated {
          isAnimating = true
        }
      }
      .onDisappear {
        isAnimating = false
      }
  }
}

private struct BubbleSystemView: View {
  @Binding var isAnimating: Bool
  var animated: Bool
  var size: CGFloat

  var body: some View {
    let colors: [Color] = [
      Color(NSColor.systemTeal.blended(withFraction: 0.5, of: .white)!),
      Color(NSColor.systemCyan.blended(withFraction: 0.5, of: .white)!),
      Color(NSColor.systemGreen.blended(withFraction: 0.5, of: .white)!),
      Color(NSColor.systemMint.blended(withFraction: 0.5, of: .white)!)
    ]
    ZStack {
      ForEach(0..<10, id: \.self) { index in
        let animationDuration = Double.random(in: 1.0..<6.0)
        BubbleView(size: size * CGFloat.random(in: 0.25..<0.35))
          .colorMultiply(colors.randomElement() ?? .white)
          .opacity(isAnimating ? 1 : 0)
          .animation(
            Animation.snappy(duration: animationDuration)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )
          .scaleEffect(isAnimating ? 1 : 0)
          .animation(
            Animation.snappy(duration: animationDuration)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )
          .rotationEffect(.degrees(isAnimating ? Double.random(in: -45..<45) : 0))
          .offset(
            x: isAnimating ? CGFloat.random(in: -size/2..<(size/2)) : 0,
            y: isAnimating ? CGFloat.random(in: -size/2...(-size/4)) : size / 2
          )
          .animation(
            Animation.easeInOut(duration: animationDuration)
              .repeatForever(autoreverses: true),
            value: isAnimating
          )
          .onAppear {
            guard animated else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
              isAnimating = true
            }
          }
      }
    }
  }
}

private struct BubbleView: View {
  private let size: CGFloat

  init(size: CGFloat) {
    self.size = size
  }

  var body: some View {
    ZStack {
      Group {
        Circle()
          .stroke(
            Color.white
          )
          .mask {
            LinearGradient(
              stops: [
                .init(color: .clear, location: 0.25),
                .init(color: .white, location: 1),
              ],
              startPoint: .bottomLeading,
              endPoint: .topTrailing
            )
          }

        RadialGradient(
          stops: [
            .init(color: Color.clear, location: 0.0),
            .init(color: Color.white.opacity(0.5), location: 1.0),
          ],
          center: .center,
          startRadius: 0.16 * size,
          endRadius: 0.66 * size
        )
        .mask {
          Circle()
            .fill(Color.white)
        }
        .mask {
          LinearGradient(
            stops: [
              .init(color: .clear, location: 0.4),
              .init(color: .white, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
        .compositingGroup()
        .shadow(color: .white, radius: 3, x: size * 0.02, y: size * 0.01)

        RadialGradient(
          stops: [
            .init(color: Color.white.opacity(0.4), location: 0.0),
            .init(color: Color.clear.opacity(0.5), location: 1.0),
          ],
          center: .topLeading,
          startRadius: 0.16 * size,
          endRadius: 0.66 * size
        )
        .mask {
          Circle()
            .fill(Color.white)
        }
        .compositingGroup()


        RadialGradient(
          stops: [
            .init(color: Color.clear, location: 0.0),
            .init(color: Color.white.opacity(0.5), location: 1.0),
          ],
          center: .center,
          startRadius: 0.16 * size,
          endRadius: 0.66 * size
        )
        .mask {
          Circle()
            .fill(Color.white)
        }
        .mask {
          LinearGradient(
            stops: [
              .init(color: .clear, location: 0.4),
              .init(color: .white, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
        .compositingGroup()
        .shadow(color: .white, radius: 3, x: size * 0.02, y: size * 0.01)
        .frame(width: size * 0.4, height: size * 0.4)
        .offset(x: size * 0.1, y: size * 0.4)
      }
      .frame(width: size * 0.9, height: size * 0.9)
    }
  }
}

#Preview {
  KeyboardCleanerIcon(size: 48)
}
