import Bonzai
import SwiftUI

struct Release3_22_2: View {
  enum ButtonAction {
    case done
  }

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 16) {
        ZStack {
          BugFixIconView(size: size)
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
          Text("3.22.2")
            .foregroundStyle(.white)
            .font(Font.system(size: 43, design: .rounded))
            .allowsTightening(true)
            .fontWeight(.heavy)
            .shadow(color: Color(.systemGreen), radius: 10)
        }
        .shadow(radius: 2)
        .frame(width: 300, height: size)
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
            Text("Changes")
              .font(Font.system(.headline, weight: .bold))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                MacroIconView(.record, size: 24)
                VStack(spacing: 12) {
                  Text("Supercharged Macros: Keyboard events playback just got a major reliability boost!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              HStack(alignment: .top, spacing: 12) {
                BugFixIconView(size: 24)
                VStack(alignment: .leading) {
                  Text("Precision is key: Holding down a key for X seconds now rocks decimal support.")
                  HStack(spacing: 0) {
                    Text("Shoutout to ")
                    Link("@hasantahir", destination: URL(string: "https://github.com/hasantahir")!)
                    Text(" for the heads-up!")
                  }
                }
              }

            }
            .font(Font.system(.caption2, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .frame(minHeight: 120)

        Divider()

        HStack(spacing: 4) {
          Text("Special thanks to")
          AsyncImage.init(url: URL(string: "https://avatars.githubusercontent.com/u/5180591?v=4")) { image in
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
      .roundedContainer(margin: 0)
      .padding(.top, 8)
      .padding(.horizontal, 16)

      HStack(spacing: 8) {
        Button(action: { action(.done) }, label: { Text("Groovy!") })
          .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
      }
      .padding(.top, 8)
      .padding(.bottom, 32)
      .frame(width: 410)
    }
    .background(Color(.windowBackgroundColor))
  }
}

struct Release3_22_2_Previews: PreviewProvider {
  static var previews: some View {
    Release3_22_2 { _ in }
      .previewDisplayName("Release 3.22.2")
  }
}
