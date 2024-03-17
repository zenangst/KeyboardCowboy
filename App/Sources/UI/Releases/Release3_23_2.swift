import Bonzai
import SwiftUI

struct Release3_23_2: View {
  enum ButtonAction {
    case done
  }

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 8) {
        VStack {
          HStack {
            BugFixIconView(size: size)
            UIImprovementIconView(size: size)
            KeyboardIconView("M", size: size)
          }
        }
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            VStack(alignment: .leading) {
              Text("Keyboard Cowboy")
                .font(Font.system(size: 16, design: .rounded))
              Text("3.23.2")
                .foregroundStyle(.white)
                .font(Font.system(size: 43, design: .rounded))
                .allowsTightening(true)
                .fontWeight(.heavy)
                .shadow(color: Color(.systemTeal), radius: 10)
            }
            .shadow(radius: 2)
            .frame(width: 200, height: 96)
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
        }
      }
      .padding(.top, 32)
      .padding(.horizontal, 16)

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
                BugFixIconView(size: 24)
                VStack(spacing: 12) {
                  Group {
                    Text("Fixed a bug where application-triggered workflows were inadvertently cancelled during concurrent trigger execution.")
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                KeyboardIconView("M", size: 24)
                VStack(spacing: 12) {
                  Text("Resolved an issue causing repeated keyboard events.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("Enhanced keyboard command reliability by ensuring commands are consistently sent in pairs.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                UIImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("Window notifications have been updated to remove the small round indicator when no bundles or notifications are present.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }
          }
        }
        .frame(minHeight: 210)

        Divider()

        HStack(spacing: 4) {
          Text("Special thanks to")
          AsyncImage.init(url: URL(string: "https://avatars.githubusercontent.com/u/4262050?v=4")) { image in
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
          Link("@bjrmatos", destination: URL(string: "https://github.com/bjrmatos")!)
          Text("for supporting the project ❤️")
        }
      }
      .frame(width: 475)
      .roundedContainer(margin: 0)
      .padding(.top, 8)
      .padding(.horizontal, 16)

      HStack(spacing: 8) {
        Button(action: { action(.done) }, label: { Text("Aww yeah!") })
          .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
      }
      .padding(.top, 8)
      .padding(.bottom, 32)
    }
    .background(Color(.windowBackgroundColor))
  }
}

struct Release3_23_2_Previews: PreviewProvider {
  static var previews: some View {
    Release3_23_2 { _ in }
      .previewDisplayName("Release 3.23.2")
  }
}
