import Bonzai
import SwiftUI

struct Release3_24_0: View {
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
            RelativeFocusIconView(.right, size: size)
            CommandLineIconView(size: size)
          }
          HStack {
            ScriptIconView(size: size)
            KeyboardIconView("M", size: size)
          }
        }
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            VStack(alignment: .leading) {
              Text("Keyboard Cowboy")
                .font(Font.system(size: 16, design: .rounded))
              Text("3.24.0")
                .foregroundStyle(.white)
                .font(Font.system(size: 43, design: .rounded))
                .allowsTightening(true)
                .fontWeight(.heavy)
                .shadow(color: Color(.systemPink), radius: 10)
            }
            .shadow(radius: 2)
            .frame(width: 304, height: 96)
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
            BugFixIconView(size: size)
            MagicVarsIconView(size: size)
            EnvironmentIconView(size: size)
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
                RelativeFocusIconView(.right, size: 24)
                Group {
                  Text("Introducing relative focus: navigate between windows like a boss! Just point the direction and let Keyboard Cowboy figure it out.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
              }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                CommandLineIconView(size: 24)
                Group {
                  Text("New command line feature in beta: launch and switch apps, search the web, GitHub, and IMDb. It's a bit rough, but oh so promising!")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
              }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                ScriptIconView(size: 24)
                VStack(alignment: .leading, spacing: 12) {
                  Group {
                    Text("Running shell scripts no longer blocks the main app. Multitasking, here we come!")

                    Text("Script commands now have their own command panel, showcasing the output of their execution. Fancy, right?")

                    Text("Shell scripts now support shebangs. Because why not?")
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
              }
            }

            Spacer()


            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                MagicVarsIconView(size: 24)
                Group {
                  Text("Script commands can now assign their output to variables for reuse in future commands. Efficiency at its finest!")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
              }
            }

            Spacer()


            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                BugFixIconView(size: 24)
                VStack(spacing: 12) {
                  Group {
                    Text("Fixed a bug where application-triggered workflows were inadvertently cancelled during concurrent trigger execution.")

                    Text("Squashed a bug where bezel notifications would get stuck at 'Running…' if the script failed. No more endless running!")
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                KeyboardIconView("M", size: 24)
                VStack(spacing: 12) {
                  Text("Fixed a bug where application-triggered workflows were inadvertently cancelled during concurrent trigger execution. Smooth sailing now!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("Enhanced keyboard command reliability by ensuring commands are consistently sent in pairs. Consistency is key!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top, spacing: 12) {
                UIImprovementIconView(size: 24)
                VStack(spacing: 12) {
                  Group {
                    Text("Window notifications no longer show the small round indicator when no bundles or notifications are present. Clean and clear!")

                    Text("Keyboard Cowboy's main window now remembers both size and position. Talk about a sharp memory!")

                    Text("Finding workflows is easier than ever with our improved filtering algorithm. Just type 'command' and watch the magic happen!")
                  }
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Divider()
                }
              }
            }
          }
        }
        .frame(minHeight: 210)

        Divider()

        FlowLayout(itemSpacing: 8) {
          Group {
            Text("Special thanks to")
            SponsorView(
              imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4044886?v=4")!,
              githubHandle: "uwe-schwarz")
            SponsorView(
              imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4262050?v=4"),
              githubHandle: "bjrmatos")
            SponsorView(
              imageUrl: URL(string: "https://avatars.githubusercontent.com/u/2284279?v=4"),
              githubHandle: "onmyway133")
            Text("and")
            SponsorView(
              imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1260095?v=4"),
              githubHandle: "andreasoverland")
            Text("for supporting the project ❤️")
          }
          .frame(minHeight: 24)
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

private struct SponsorView: View {
  let imageUrl: URL?
  let githubHandle: String

  var body: some View {
    HStack(spacing: 4) {
      AsyncImage.init(url: imageUrl) { image in
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
      Link("@\(githubHandle)", destination: URL(string: "https://github.com/\(githubHandle)")!)
    }
  }
}

struct Release3_24_0_Previews: PreviewProvider {
  static var previews: some View {
    Release3_24_0 { _ in }
      .previewDisplayName("Release 3.24.0")
  }
}
