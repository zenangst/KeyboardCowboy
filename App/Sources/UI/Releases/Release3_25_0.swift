import Bonzai
import SwiftUI

struct Release3_25_0: View {
  enum ButtonAction {
    case done
  }

  private let changes: [Change<AnyView>] = [
    Change(icon: { WorkspaceIcon(size: 24).anyView },
           text: "Level up your macOS productivity with Workspaces."),

    Change(icon: { WindowTilingIcon(kind: .arrangeLeftQuarters, size: 24).anyView },
           text: "Smart Window Tiling in macOS Sequoia."),

    Change(icon: { AppFocusIcon(size: 24).anyView },
           text: "Get your focus on with the new App Focus command."),

    Change(icon: { AppPeekIcon(size: 24).anyView },
           text: "Quick peek at your apps with the new peek functionality for the application command."),

    Change(icon: { RelativeFocusIconView(.upperRight, size: 24).anyView },
           text: "Fly between applications with the new quarter & center focus commands."),

    Change(icon: { RepeatLastWorkflowIconView(size: 24).anyView },
           text: "Easily repeat your last workflow or keyboard event."),

    Change(icon: { HideAllIconView(size: 24).anyView },
           text: "Clean up your workspace with the new smart hide all other apps command."),

    Change(icon: { KeyboardCleanerIcon(size: 24, animated: false).anyView },
           text: "Clean your keyboard has never been easier with 'Keyboard Cleaner'."),

    Change(icon: { GenericAppIconView(size: 24).anyView },
           text: "Application commands now support 'wait until launched'."),

    Change(icon: { ActivateLastApplicationIconView(size: 24).anyView },
           text: "Activating the last application command is now more reliable."),

    Change(icon: { MoveFocusToWindowIconView(direction: .next, scope: .allWindows, size: 24).anyView },
           text: "Moving focus between windows is now more accurate."),

    Change(icon: { MacroIconView(.record, size: 24).anyView },
           text: "You can now prefix macros with iterations."),

    Change(icon: { RelativeFocusIconView(.right, size: 24).anyView },
           text: "The scanning algorithm has been completely rewritten to improve relative focus."),

    Change(icon: { WindowManagementIconView(size: 24).anyView },
           text: "Moving windows between monitors is now more accurate."),

    Change(icon: { TriggersIconView(size: 24).anyView },
           text: "Application Triggers now support 'any Application'."),

    Change(icon: { UIImprovementIconView(size: 24).anyView },
           text: "Notifications is now powered by DynamicNotchKit."),

    Change(icon: { BugFixIconView(size: 24).anyView },
           text: "Loads of bug fixes!"),

  ]

  private let supporters = [
    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/2284279?v=4"),
      githubHandle: "onmyway133"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4262050?v=4"),
      githubHandle: "bjrmatos"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1260095?s=52&v=4")!,
      githubHandle: "andreasoverland"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/68963405?v=4"),
      githubHandle: "MrKai77"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/4584594?s=96&v=4"),
      githubHandle: "murdahl"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/620789?s=96&v=4"),
      githubHandle: "hansoln"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/47497819?v=4"),
      githubHandle: "Moelfarri"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/555305?s=96&v=4"),
      githubHandle: "t0ggah"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/32518292?s=96&v=4"),
      githubHandle: "Abenayan"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/378235?v=4"),
      githubHandle: "timkurvers"),

    Supporter(
      imageUrl: URL(string: "https://avatars.githubusercontent.com/u/386122?v=4"),
      githubHandle: "sindrenm"),

  ]

  let size: CGFloat = 96
  let action: (ButtonAction) -> Void

  var body: some View {
    VStack(spacing: 8) {
      HStack(alignment: .bottom, spacing: -16) {
        WindowTilingIcon(kind: .arrangeLeftQuarters, size: 128)
          .rotation3DEffect(.degrees(10), axis: (x: 1, y: 1, z: -1))
          .zIndex(9)
        WorkspaceIcon(size: 128)
          .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: 1))
          .shadow(radius: 30)
          .zIndex(10)
        AppPeekIcon(size: 128)
          .rotation3DEffect(.degrees(2.5), axis: (x: 1, y: 0, z: -1))
          .shadow(radius: 30)
          .zIndex(10)
        AppFocusIcon(size: 128)
          .rotation3DEffect(.degrees(10), axis: (x: 1, y: 0, z: 1))
          .zIndex(9)
      }
      .overlay(alignment: .bottom) {
        HStack(alignment: .center) {
          Text("Keyboard Cowboy")
            .font(Font.system(size: 20, design: .rounded))
          Text("3.25.0")
            .foregroundStyle(.white)
            .font(Font.system(size: 24, design: .rounded))
            .allowsTightening(true)
            .fontWeight(.heavy)
            .shadow(color: Color(.systemPurple), radius: 10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .shadow(radius: 2)
        .fixedSize()
        .background {
          Rectangle()
            .fill(
              LinearGradient(
                stops: [
                  Gradient.Stop(color: .black.opacity(0.75), location: 0.5),
                  Gradient.Stop(color: .black, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
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
        .offset(y: 16)
      }
      .padding(.top, 16)

      ZenDivider(.horizontal)

      VStack(alignment: .leading, spacing: 0) {
        Text("Changes")
          .font(Font.system(.headline, weight: .bold))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
        ScrollView(.vertical) {
          VStack(spacing: 16) {
            Grid {
              ForEach(changes, id: \.text) { change in
                GridRow {
                  change.icon
                  ZenDivider(.vertical)
                  Text(change.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
            }
            .padding(.bottom, 16)
          }
          .padding(16)
        }
        .scrollIndicators(.visible)
        .scrollContentBackground(.visible)
        .frame(minHeight: 210)

        Divider()

        Text("Special thanks to")
          .bold()
          .padding(8)
        FlowLayout(itemSpacing: 4) {
          Group {
            ForEach(Array(zip(supporters.indices, supporters)), id: \.1.githubHandle) { offset, supporter in
              if offset == supporters.count - 1 {
                Text("&")
              }
              SponsorView(imageUrl: supporter.imageUrl, githubHandle: supporter.githubHandle)
            }
            Text("for supporting the project ❤️")
          }
          .frame(minHeight: 24)
        }
        .padding([.leading, .trailing, .bottom], 8)
      }
      .frame(width: 500)
      .roundedContainer(padding: 0, margin: 0)
      .padding(.top, 8)

      HStack(spacing: 8) {
        Button(action: { action(.done) }, label: { Text("LFG! 🍍🤘") })
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
    Button(action: { }) {
      HStack {
        AsyncImage.init(url: imageUrl) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .mask { Circle() }
        } placeholder: {
          Circle()
            .fill(Color(.controlAccentColor))
            .frame(width: 16, height: 16)
            .overlay {
              ProgressView()
            }
        }
        Link("\(githubHandle)", destination: URL(string: "https://github.com/\(githubHandle)")!)
          .font(.body)
          .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(2)
    .buttonStyle(.zen(.init(
      calm: true,
      color: .accentColor,
      focusEffect: .constant(false),
      padding: .small)))
  }
}

private struct Supporter {
  let imageUrl: URL?
  let githubHandle: String
}

private struct Change<Content> where Content: View {
  let icon: AnyView
  let text: String

  init(@ViewBuilder icon: @escaping () -> Content, text: String) {
    self.icon = AnyView(icon())
    self.text = text
  }
}

private extension View {
  var anyView: AnyView { AnyView(self) }
}

struct Release3_25_0_Previews: PreviewProvider {
  static var previews: some View {
    Release3_25_0 { _ in }
      .previewDisplayName("Release 3.25.0")
  }
}
