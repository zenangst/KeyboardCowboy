import SwiftUI

struct SplashView: View {
  @State var animating: Bool = false
  @Binding var done: Bool

  var body: some View {
    ZStack {
      Canvas(rendersAsynchronously: true) { context, size in
        context.fill(path(), with: .color(.white))
      }
      .offset(x: animating ? 80 : 180,
              y: animating ? 80 : 180)
      .opacity(0.2)
      .scaleEffect(0.5)
      .animation(.easeInOut(duration: 1.0), value: done)

      Canvas(rendersAsynchronously: true) { context, size in
        context.fill(path(), with: .color(Color(red: 114/255, green: 59/255, blue: 120/255)))
      }
      .scaleEffect(done ? 4 : 1.75)
      .rotationEffect(.degrees(animating ? 45 : 10))
      .opacity(0.7)
      .offset(x: animating ? 80 : 180,
              y: animating ? 80 : 180)
      .animation(.easeInOut(duration: 5.75).delay(0.15).repeatForever(), value: animating)
      .animation(.easeInOut(duration: 1.0), value: done)


      Canvas(rendersAsynchronously: true) { context, size in
        context.fill(path(), with: .color(Color(red: 220/255, green: 58/255, blue: 102/255)))
      }
      .scaleEffect(done ? 2 : 0.75)
      .rotationEffect(.degrees(animating ? 45 : -45))

      .offset(x: animating ? 80 : 180,
              y: animating ? 80 : 180)
      .opacity(0.4)
      .animation(.easeInOut(duration: 3.75).repeatForever(), value: animating)
      .animation(.easeInOut(duration: 1.0), value: done)
    }
    .blur(radius: 40)
    .background(Color(red: 22/255, green: 23/255, blue: 48/255))
    .onAppear {
      animating = true
    }
  }

  private func path() -> Path {
    Path { path in
      path.move(to: CGPoint(x: 366, y: 270))
      path.addCurve(to: CGPoint(x: 349, y: 327), control1: CGPoint(x: 336.5, y: 282.333333), control2: CGPoint(x: 330.833333, y: 301.333333))
      path.addCurve(to: CGPoint(x: 342, y: 383), control1: CGPoint(x: 358.333333, y: 349), control2: CGPoint(x: 356, y: 367.666667))
      path.addCurve(to: CGPoint(x: 309, y: 432), control1: CGPoint(x: 333.333333, y: 396), control2: CGPoint(x: 322.333333, y: 412.333333))
      path.addCurve(to: CGPoint(x: 252, y: 458), control1: CGPoint(x: 276, y: 462.666667), control2: CGPoint(x: 295, y: 454))
      path.addCurve(to: CGPoint(x: 191, y: 424), control1: CGPoint(x: 227, y: 455.666667), control2: CGPoint(x: 206.666667, y: 444.333333))
      path.addCurve(to: CGPoint(x: 104, y: 396), control1: CGPoint(x: 141.666667, y: 393.666667), control2: CGPoint(x: 170.666667, y: 403))
      path.addCurve(to: CGPoint(x: 74, y: 355), control1: CGPoint(x: 76.5, y: 398.666667), control2: CGPoint(x: 66.5, y: 385))
      path.addCurve(to: CGPoint(x: 40, y: 286), control1: CGPoint(x: 65.959137, y: 305.983419), control2: CGPoint(x: 77.29247, y: 328.983419))
      path.addCurve(to: CGPoint(x: 47, y: 215.993744), control1: CGPoint(x: 34.5, y: 239.329163), control2: CGPoint(x: 32.166667, y: 262.664581))
      path.addCurve(to: CGPoint(x: 66.5, y: 140.993744), control1: CGPoint(x: 63.5, y: 168.327077), control2: CGPoint(x: 57, y: 193.327077))
      path.addCurve(to: CGPoint(x: 95, y: 65), control1: CGPoint(x: 77.833333, y: 87.664591), control2: CGPoint(x: 68.333333, y: 112.995839))
      path.addCurve(to: CGPoint(x: 173, y: 76), control1: CGPoint(x: 120.712545, y: 46.25885), control2: CGPoint(x: 146.712545, y: 49.925517))
      path.addCurve(to: CGPoint(x: 245.5, y: 139.993744), control1: CGPoint(x: 189.510427, y: 101.58962), control2: CGPoint(x: 213.677094, y: 122.920868))
      path.addCurve(to: CGPoint(x: 313, y: 125), control1: CGPoint(x: 288.645976, y: 141.967122), control2: CGPoint(x: 266.145976, y: 146.965037))
      path.addCurve(to: CGPoint(x: 395, y: 102), control1: CGPoint(x: 373.197957, y: 101.394002), control2: CGPoint(x: 345.864624, y: 109.060669))
      path.addCurve(to: CGPoint(x: 365, y: 170), control1: CGPoint(x: 397.666667, y: 134.333333), control2: CGPoint(x: 407.666667, y: 111.666667))
      path.addCurve(to: CGPoint(x: 380, y: 235), control1: CGPoint(x: 348, y: 224.5), control2: CGPoint(x: 343, y: 202.833333))
      path.addCurve(to: CGPoint(x: 366, y: 270), control1: CGPoint(x: 404.5, y: 259), control2: CGPoint(x: 409.166667, y: 247.333333))
      path.closeSubpath()
    }
  }
}

fileprivate final class SplashDemo: ObservableObject {
  @Published var done: Bool = false
}

struct SplashView_Previews: PreviewProvider {
  @ObservedObject fileprivate static var publisher = SplashDemo()
  static var previews: some View {
    SplashView(done: $publisher.done)
      .overlay {
        Button(action: { publisher.done.toggle() }, label: {
          Text("Try me!")
        })
      }
  }
}

