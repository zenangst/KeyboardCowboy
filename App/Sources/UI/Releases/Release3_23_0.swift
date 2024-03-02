import Bonzai
import SwiftUI

struct Release3_23_0: View {
  enum ButtonAction {
    case done
  }

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 16) {
        ZStack {
          SnippetIconView(size: size)
            .scaleEffect(0.8)
            .offset(y: -24)
            .opacity(0.5)
          SnippetIconView(size: size)
            .scaleEffect(0.9)
            .offset(y: -12)
            .shadow(radius: 2)
            .opacity(0.5)
          SnippetIconView(size: size)
            .shadow(radius: 2)
        }
        VStack(alignment: .leading) {
          Text("Keyboard Cowboy")
            .font(Font.system(size: 16, design: .rounded))
          Text("3.23.0")
            .foregroundStyle(.white)
            .font(Font.system(size: 43, design: .rounded))
            .allowsTightening(true)
            .fontWeight(.heavy)
            .shadow(color: Color(.systemPink), radius: 10)
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
            HStack(spacing: 12) {
              SnippetIconView(size: 32)
              Text("Snippet: write more with less")
                .font(Font.system(.title2, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Introducing Snippet triggers, small trigger words that expand into a collection of workflows running, at your command.")
              .fixedSize(horizontal: false, vertical: true)

            Divider()
              .padding(.vertical, 8)

            Text("Other Changes")
              .font(Font.system(.headline, weight: .bold))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                UIElementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("UI element capturing now work for Electron-based applications, such as Spotify, Slack and Discord.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }

              HStack(alignment: .top, spacing: 12) {
                ImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("Commands that rely on the pasteboard is now a whole lot more realiable across the board.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }

              HStack(alignment: .top, spacing: 12) {
                UIImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("The User Modes have been move to the bottom of the sidebar")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }

              
            }
            .font(Font.system(.caption2, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .frame(minHeight: 200)
      }
      .frame(width: 380)
      .roundedContainer(margin: 0)
      .padding(.top, 8)
      .padding(.horizontal, 16)

      HStack(spacing: 8) {
        Button(action: { action(.done) }, label: { Text("Snipp Snapp Snute!") })
          .buttonStyle(.zen(.init(color: .systemGreen, hoverEffect: .constant(false))))
      }
      .padding(.top, 8)
      .padding(.bottom, 32)
      .frame(width: 410)
    }
    .background(Color(.windowBackgroundColor))
  }
}

struct Release3_23_0_Previews: PreviewProvider {
  static var previews: some View {
    Release3_23_0 { _ in }
      .previewDisplayName("Release 3.23.0")
  }
}
