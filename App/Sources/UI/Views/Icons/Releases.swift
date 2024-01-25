import SwiftUI

struct Release3_21_0: PreviewProvider {
  static let size: CGFloat = 96
  static var previews: some View {
    VStack {
      HStack {
        DockIconView(size: size)
        MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: size)
        MenuIconView(size: size)
        MouseIconView(size: size)
        MissionControlIconView(size: size)
      }

      HStack {
        ScriptIconView(size: size)
        TypingIconView(size: size)

        VStack(alignment: .leading) {
          Text("Keyboard Cowboy")
            .font(Font.system(size: 16, design: .rounded))
          Text("3.21.0")
            .foregroundStyle(.white)
            .font(Font.system(size: 43, design: .rounded))
            .allowsTightening(true)
            .fontWeight(.heavy)
            .shadow(color: .white, radius: 10)
        }
        .shadow(radius: 10)
        .frame(width: 200, height: size)
        .fixedSize()
        .background {
          Rectangle()
            .fill(.black)
            .overlay {
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
        .iconShape(size)

        UIElementIconView(size: size)
      }

      HStack {
        WindowManagementIconView(size: size)
        MinimizeAllIconView(size: size)
        ActivateLastApplicationIconView(size: size)
        MoveFocusToWindowIconView(direction: .previous, scope: .visibleWindows, size: size)
        KeyboardIconView("M", size: size)
      }
    }
    .padding(64)
    .background(Color(.windowBackgroundColor))
  }
}

