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
      HStack(spacing: 8) {
        VStack(spacing: 8) {
          SnippetIconView(size: size)
          BugFixIconView(size: size)
        }
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            UIElementIconView(size: size)
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
          }

          HStack {
            WindowManagementIconView(size: size)
            UIImprovementIconView(size: size)
            TypingIconView(size: size)
          }
        }
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
              Text("Snippet Magic: Write more with less")
                .font(Font.system(.title2, design: .rounded, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("Tiny trigger words now unleash mighty workflow wonders – all at your command.")
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
                  Text("Capture UI elements in Electron apps like a boss – Spotify, Slack, and Discord, now fully at your mercy.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }

              HStack(alignment: .top, spacing: 12) {
                WindowManagementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("Anchoring perfected. No more window pile-ups, just smooth resizing for a seamless view.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }

              HStack(alignment: .top, spacing: 12) {
                TypingIconView(size: 24)
                VStack(spacing: 12) {
                  Text("Text commands now wield the $PASTEBOARD sorcery, turning your clipboard contents into instant command fuel.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }

              HStack(alignment: .top, spacing: 12) {
                UIImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("- User Modes strut down to the sidebar's end, making room for spotlight-stealers.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("- The workflow notifications have gotten a UI makeover.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("- User Modes now flaunt an iconic new symbol of identity.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("- Sprinkling in a dash of pictographic pizzazz across the UI.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }

              HStack(alignment: .top, spacing: 12) {
                ImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Text("- Across-the-board reliability boost for pasteboard-dependent commands — like magic, but realer.")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("- Dive straight into recording mode for shortcuts — no extra clicks, just slick picks.")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("- Internal tweaks squash notification echoes for a smoother info flow.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }

              HStack(alignment: .top, spacing: 12) {
                BugFixIconView(size: 24)
                VStack(spacing: 6) {
                  Text("- Notifications vanish gracefully with a new shortcut summon – no lingering farewells.")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("- Squashed the gremlins that bungled simultaneous User Mode mojo — harmony restored.")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("- 'New Command' now strutting its stuff in the File menu")
                    .frame(maxWidth: .infinity, alignment: .leading)

                  Text("- Swatted those pesky glitches for a buttery-smooth operation.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
            }
            .font(Font.system(.caption2, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .frame(minHeight: 380)
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
