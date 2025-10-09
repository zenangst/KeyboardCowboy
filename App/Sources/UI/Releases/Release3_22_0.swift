import Bonzai
import SwiftUI

struct Release3_22_0: View {
  enum ButtonAction {
    case wiki
    case done
  }

  let size: CGFloat = 128
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 16) {
        ZStack {
          MacroIconView(.record, size: size)
            .scaleEffect(0.8)
            .offset(y: -24)
            .opacity(0.5)
          MacroIconView(.record, size: size)
            .scaleEffect(0.9)
            .offset(y: -12)
            .shadow(radius: 2)
            .opacity(0.5)
          MacroIconView(.record, size: size)
            .shadow(radius: 2)
        }
        VStack(alignment: .leading) {
          Text("Keyboard Cowboy")
            .font(Font.system(size: 16, design: .rounded))
          Text("3.22.0")
            .foregroundStyle(.white)
            .font(Font.system(size: 43, design: .rounded))
            .allowsTightening(true)
            .fontWeight(.heavy)
            .shadow(color: Color(.systemCyan), radius: 10)
        }
        .shadow(radius: 2)
        .frame(width: 268, height: size)
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
      }
      .padding(.top, 32)

      ZenDivider()
        .frame(maxWidth: 400)
        .padding(.top, 8)

      VStack(alignment: .leading, spacing: 16) {
        ScrollView(.vertical) {
          VStack(spacing: 6) {
            HStack(spacing: 12) {
              MacroIconView(.record, size: 32)
              Text("Macros: Make Every Keystroke Count!")
                .font(Font.system(.title2, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Rev up your routine with Macros — where doing less isn't just more; it's epic. Say hello to keyboard wizardry that conjures up workflows in the blink of an eye.")
              .fixedSize(horizontal: false, vertical: true)
            Text("With Macros, you're not just efficient, you're effortlessly epic!")

            Divider()
              .padding(.vertical, 8)

            Text("Other changes")
              .font(Font.system(.headline, weight: .bold))
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
              HStack(spacing: 12) {
                BugFixIconView(size: 24)
                Text("Banishes the ghosted icons — they're all back with a vengeance!")
              }

              HStack(alignment: .top, spacing: 12) {
                ImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("Smooth Operator: Your Keyboard, Menu, and Window Commands now nail those encores like a pro!")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("Window-hopping within your go-to app just got a snappy upgrade—slick, reliable, and ready to roll!")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("Icons revamped – a subtle glow-up for your visual pleasure!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
            }
            .font(Font.system(.caption2, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .frame(minHeight: 220)

        Divider()

        HStack(spacing: 4) {
          Text("Special thanks to")
          AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/5180591?v=4")) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
              .mask { Circle() }
          } placeholder: {
            Circle()
              .fill(Color(.controlAccentColor))
              .frame(width: 24, height: 24)
              .overlay {
                ProgressView()
              }
          }
          Link("@bforpc", destination: URL(string: "https://github.com/bforpc")!)
          Text("for supporting the project ❤️")
        }
      }
      .frame(width: 380)
      .roundedStyle()
      .padding(.top, 8)
      .padding(.horizontal, 16)

      HStack(spacing: 8) {
        Button(action: { action(.wiki) }, label: { Text("About Macros") })
        Button(action: { action(.done) }, label: { Text("Got it!") })
      }
      .padding(.top, 8)
      .padding(.bottom, 32)
      .frame(width: 410)
    }
    .background(Color(.windowBackgroundColor))
  }
}

struct Release3_22_0_Previews: PreviewProvider {
  static var previews: some View {
    Release3_22_0 { _ in }
      .previewDisplayName("Release 3.22.0")
  }
}
