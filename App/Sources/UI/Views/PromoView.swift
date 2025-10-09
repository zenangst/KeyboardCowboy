import Bonzai
import SwiftUI

struct PromoView: View {
  private let iconSize: CGFloat = 48
  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 16) {
            PrivacyFirstView()
              .frame(width: 128, height: 128)
              .padding(8)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 16))

            ActionPackedView()
              .frame(width: 256, height: 128)
              .padding(8)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 16))

            AutomationView()
              .frame(width: 148, height: 128)
              .padding(8)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 16))
          }

          HStack(spacing: 16) {
            VStack(spacing: 16) {
              WorkspacesPromoView()
                .frame(width: 117, height: 117)
                .padding(8)
                .background(
                  WorkspaceBackgroundView(),
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

              AppFocusPromoView()
                .frame(width: 117, height: 117)
                .padding(8)
                .background(
                  AppFocusBackground(),
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            KeyboardCowboyView()
          }
        }

        VStack(spacing: 16) {
          ScriptRunnerView()
            .padding(16)
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 16))

          HStack(spacing: 0) {
            ContextualGroupsView()
              .padding(12)
              .background(Color(nsColor: .controlAccentColor.blended(withFraction: 0.7, of: .black)!))
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .frame(width: 128, height: 128)
              .padding(8)
            UIScriptingView()
              .frame(width: 128, height: 128)
              .padding(8)
            WindowManagementView(.init(width: 56, height: 56))
              .frame(width: 128, height: 128)
              .shadow(radius: 2)
              .background(
                WindowManagementIconBackgroundView(),
              )
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .padding(8)
          }
        }
      }

      HStack(spacing: 16) {
        WindowTilingPromoView()
          .shadow(color: Color(.white), radius: 15, y: 2)
          .frame(width: 200, height: 148)
          .padding(16)
          .background(
            WindowTilingBackgroundView(),
          )
          .clipShape(RoundedRectangle(cornerRadius: 16))

        ApplicationLauncherView()
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        UniqueModifierView()
          .frame(width: 148, height: 148)
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        MuchMoreView()
          .frame(width: 148, height: 148)
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
    }
    .font(.system(size: 18, design: .rounded))
    .frame(width: 1024, height: 650)
    .padding(32)
    .background(.black)
  }
}

private struct AppFocusPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      Rectangle()
        .fill(Color.white.opacity(0.4))
        .overlay {
          AppFocusIconGroupView(size: 72)
        }
        .frame(width: 72, height: 72)
        .fixedSize()
        .iconShape(72)
      Text("Full App Focus")
    }
  }
}

private struct MuchMoreView: View {
  var body: some View {
    VStack {
      HStack {
        RepeatLastWorkflowIconView(size: 48)
        RelativeFocusIconView(.right, size: 48)
        HideAllIconView(size: 48)
      }
      HStack {
        MouseIconView(size: 48)
        InputSourceIcon(size: 48)
        ScriptIconView(size: 48)
      }
      HStack {
        WorkspaceIcon(.regular, size: 48)
        AppFocusIcon(size: 48)
        WindowTidyIcon(size: 48)
      }
      Text("And so much more")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
}

private struct WorkspacesPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      Rectangle()
        .fill(Color.white.opacity(0.4))
        .overlay {
          WorkspaceIconIllustration(size: 72)
        }
        .frame(width: 72, height: 72)
        .fixedSize()
        .iconShape(72)
      Text("Workspaces")
    }
    .padding(8)
  }
}

private struct WindowTilingPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      WindowTilingIcon(kind: .arrangeLeftQuarters, size: 96)
      Text("Smarter Window Tiling")
        .multilineTextAlignment(.center)
    }
    .padding(8)
  }
}

private struct AppFocusBackground: View {
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .black)!), location: 0.0),
          .init(color: Color(.purple), location: 0.6),
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom),
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemTeal), location: 0.5),
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
          .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
  }
}

private struct WindowTilingBackgroundView: View {
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 0.3),
          .init(color: Color(.cyan), location: 0.6),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom),
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 0.5),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
          .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemOrange.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
  }
}

private struct WorkspaceBackgroundView: View {
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color.blue, location: 0.0),
          .init(color: Color(.cyan), location: 0.6),
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom),
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color.blue, location: 0.5),
          .init(color: Color(.systemTeal.blended(withFraction: 0.3, of: .white)!), location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
          .opacity(0.6)
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemGreen.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
      }
  }
}

private struct ActionPackedView: View {
  var body: some View {
    VStack(spacing: 8) {
      Text("Action Packed Features")
      HStack {
        RepeatLastWorkflowIconView(size: 46)
        RelativeFocusIconView(.right, size: 46)
        TypingIconView(size: 46)
        KeyboardIconView("♾️", size: 46)
        AppPeekIcon(size: 46)
      }
      .roundedStyle()
    }
  }
}

private struct ContextualGroupsView: View {
  var body: some View {
    VStack(spacing: 16) {
      GenericAppIconView(size: 48)
      Text("Per-Application Rules")
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
    }
  }
}

private struct UserModesPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      UserModeIconView(size: 64)
      Text("User Modes")
    }
  }
}

private struct SnippetsPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      SnippetIconView(size: 64)
      Text("Snippets")
    }
  }
}

private struct MacrosPromoView: View {
  var body: some View {
    VStack(spacing: 16) {
      MacroIconView(.record, size: 64)
      Text("Macros")
    }
  }
}

private struct AutomationView: View {
  var body: some View {
    VStack(spacing: 16) {
      TriggersIconView(size: 64)
      Text("Automation\nTriggers")
        .multilineTextAlignment(.center)
    }
  }
}

private struct ApplicationLauncherView: View {
  @FocusState var focus: AppFocus?
  var body: some View {
    VStack(spacing: 0) {
      Text("Application Launcher")
      CommandView($focus,
                  command: .readonly { DesignTime.applicationCommand.model },
                  publisher: DesignTime.commandsPublisher,
                  selectionManager: SelectionManager<CommandViewModel>(),
                  workflowId: UUID().uuidString)
        .frame(minWidth: 390, maxWidth: 390)
        .designTime()
    }
  }
}

private struct ScriptRunnerView: View {
  @FocusState var focus: AppFocus?
  var body: some View {
    VStack(spacing: 16) {
      CommandView($focus,
                  command: .readonly { DesignTime.scriptCommandInline.model },
                  publisher: DesignTime.commandsPublisher,
                  selectionManager: SelectionManager<CommandViewModel>(),
                  workflowId: UUID().uuidString)
        .frame(width: 384, height: 220)
        .designTime()

      Text("Script Runner")
    }
  }
}

private struct UniqueModifierView: View {
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        ModifierKeyIcon(key: .leftShift, alignment: .bottomLeading)
          .frame(width: 48, height: 56 / 2)
        ModifierKeyIcon(key: .rightShift, alignment: .bottomTrailing)
          .frame(width: 48, height: 56 / 2)
      }
      HStack {
        ModifierKeyIcon(key: .leftOption, alignment: .topTrailing)
          .frame(width: 32, height: 32)
        ModifierKeyIcon(key: .rightOption, alignment: .topLeading)
          .frame(width: 32, height: 32)
      }
      HStack {
        ModifierKeyIcon(key: .leftCommand, alignment: .topTrailing)
          .frame(width: 48, height: 56 / 2)
        ModifierKeyIcon(key: .rightCommand, alignment: .topLeading)
          .frame(width: 48, height: 56 / 2)
      }
      .aspectRatio(contentMode: .fill)
      Text("Unique Modifiers")
    }
  }
}

private struct PrivacyFirstView: View {
  var body: some View {
    VStack(spacing: 16) {
      PrivacyIconView(size: 64)
      Text("Privacy First")
    }
  }
}

private struct KeyboardCowboyView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 0) {
        Image(.applicationIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 148)
          .padding(.leading, 0)
          .padding(.trailing, 32)
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 0) {
            Text("Keyboard")
            Text("Cowboy")
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(size: 48, design: .rounded))
        }
      }
      ZenDivider()

      HStack {
        Spacer()
        Text("Version")
        Text("3.27.0")
          .fontWeight(.bold)
        Spacer()
      }
      .font(.title)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
    .frame(width: 431, height: 252)
    .padding(16)
    .background {
      BackgroundView()
    }
    .background(
      LinearGradient(stops: [
        .init(color: Color(.systemGray.blended(withFraction: 0.1, of: .black)!).opacity(0.8), location: 0),
        .init(color: Color(.systemGray.blended(withFraction: 0.6, of: .black)!).opacity(0.9), location: 0.5),
        .init(color: Color(.systemGray.blended(withFraction: 0.7, of: .black)!), location: 1.0),
      ], startPoint: .topLeading, endPoint: .bottom),
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

private struct BackgroundView: View {
  @ObservedObject private var publisher: ColorPublisher = .shared
  var body: some View {
    Color.clear
      .background {
        Ellipse()
          .fill(
            LinearGradient(stops: [
              .init(color: Color.systemPink, location: 0),
              .init(color: Color.systemOrange, location: 0.5),
              .init(color: Color.systemTeal, location: 0.75),
              .init(color: Color.black, location: 1),
            ], startPoint: .top, endPoint: .bottom),
          )
      }
      .mask {
        LinearGradient(stops: [
          .init(color: .black.opacity(0.5), location: 0.5),
          .init(color: .black, location: 1),
        ], startPoint: .top, endPoint: .bottom)
      }
      .blur(radius: 50)
      .frame(maxWidth: 500)
  }
}

private struct WindowManagementView: View {
  let size: CGSize

  init(_ size: CGSize) {
    self.size = size
  }

  var body: some View {
    VStack(spacing: 8) {
      Rectangle()
        .fill(
          LinearGradient(stops: [
            .init(color: Color(nsColor: .white), location: 0.0),
            .init(color: Color(nsColor: .white.withSystemEffect(.disabled)), location: 1.0),
          ], startPoint: .topLeading, endPoint: .bottom),
        )
        .overlay { iconOverlay().opacity(0.25) }
        .overlay(alignment: .topLeading) {
          HStack(alignment: .top, spacing: 0) {
            MinimizeAllWindowTrafficLightsView(size)
            Rectangle()
              .fill(.white)
              .frame(maxWidth: .infinity)
              .overlay { iconOverlay().opacity(0.25) }
          }
        }
        .iconShape(size.width * 0.7)
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

      Text("Window Management")
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
    .padding()
  }
}

private struct MinimizeAllWindowTrafficLightsView: View {
  let size: CGSize

  init(_ size: CGSize) {
    self.size = size
  }

  var body: some View {
    HStack(alignment: .top, spacing: size.width * 0.0_240) {
      Circle()
        .fill(Color(.systemRed))
        .grayscale(0.5)
      Circle()
        .fill(Color(.systemYellow))
        .shadow(color: Color(.systemYellow), radius: 10)
        .overlay(alignment: .center) {
          Image(systemName: "minus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fontWeight(.heavy)
            .foregroundStyle(Color.orange)
            .opacity(0.8)
            .frame(width: size.width * 0.06)
        }
      Circle()
        .fill(Color(.systemGreen))
        .grayscale(0.5)
      Divider()
        .frame(width: 1)
    }
    .frame(width: size.width * 0.4)
    .padding([.leading, .top], size.width * 0.0675)
  }
}

private struct UIScriptingView: View {
  var body: some View {
    Color(.controlAccentColor)
      .overlay {
        UIElementIconGradientView()
      }
      .overlay {
        Text("UI Scripting")
          .font(.system(size: 18, design: .rounded))
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

#Preview {
  PromoView()
}
