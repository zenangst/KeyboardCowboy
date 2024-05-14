import Bonzai
import SwiftUI

struct PromoView: View {
  private let iconSize: CGFloat = 48
  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 16) {
              PrivacyFirstView()
                .frame(minWidth: 128, minHeight: 128)
                .padding(8)
                .background()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            ActionPackedView()
              .frame(minWidth: 128, minHeight: 128)
              .padding(8)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 16))

            AutomationView()
              .frame(minWidth: 128, minHeight: 128)
              .padding(8)
              .background()
              .clipShape(RoundedRectangle(cornerRadius: 16))
          }

          HStack(spacing: 16) {
            WindowManagementView(.init(width: 64, height: 64))
              .frame(minWidth: 128, minHeight: 128)
              .padding(16)
              .shadow(radius: 2)
              .background(
                WindowManagementIconBackgroundView()
              )
              .clipShape(RoundedRectangle(cornerRadius: 16))
            KeyboardCowboyView()
          }
        }

        ScriptRunnerView()
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }

      HStack(spacing: 16) {
        ContextualGroupsView()
          .frame(minWidth: 128, minHeight: 128)
          .padding(16)
          .background(Color(nsColor: .controlAccentColor.blended(withFraction: 0.7, of: .black)!))
          .clipShape(RoundedRectangle(cornerRadius: 16))

        ApplicationLauncherView()
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        UniqueModifierView()
          .padding(16)
          .background()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        UIScriptingView()
      }
    }
    .font(.system(size: 18, design: .rounded))
    .frame(width: 1024, height: 512)
    .padding(32)
    .background(.black)
  }
}

private struct ActionPackedView: View {
  var body: some View {
    VStack(spacing: 8) {
      Text("Action Packed Features")
      HStack {
        MacroIconView(.record, size: 64)
        SnippetIconView(size: 64)
        RelativeFocusIconView(.right, size: 64)
        TypingIconView(size: 64)
        KeyboardIconView("♾️", size: 64)
      }
      .roundedContainer(margin: 0)
    }
  }
}

private struct ContextualGroupsView: View {
  var body: some View {
    VStack(spacing: 16) {
      GenericAppIconView(size: 64)
      Text("Per-Application Rules")
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
      Text("Automation")
    }
  }
}


private struct ApplicationLauncherView: View {
  @FocusState var focus: AppFocus?
  var body: some View {
    VStack(spacing: 16) {
      Text("Application Launcher")
      CommandView($focus,
                  command: .readonly(DesignTime.applicationCommand.model),
                  publisher: DesignTime.commandsPublisher,
                  selectionManager: SelectionManager<CommandViewModel>(),
                  workflowId: UUID().uuidString,
                  onCommandAction: {
        _ in
      },
                  onAction: {
        _ in
      })
      .frame(minWidth: 390)
      .designTime()

    }
  }
}

private struct ScriptRunnerView: View {
  @FocusState var focus: AppFocus?
  var body: some View {
    VStack(spacing: 16) {
      CommandView($focus,
                  command: .readonly(DesignTime.scriptCommandInline.model),
                  publisher: DesignTime.commandsPublisher,
                  selectionManager: SelectionManager<CommandViewModel>(),
                  workflowId: UUID().uuidString,
                  onCommandAction: {
        _ in
      },
                  onAction: {
        _ in
      })
      .frame(maxWidth: 390)
      .designTime()

      Text("Script Runner")
    }
  }
}

private struct UniqueModifierView: View {
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        ModifierKeyIcon(key: .shift, alignment: .bottomLeading)
          .frame(width: 48, height: 56 / 2)
        ModifierKeyIcon(key: .shift, alignment: .bottomTrailing)
          .frame(width: 48, height: 56 / 2)
      }
      HStack {
        ModifierKeyIcon(key: .option, alignment: .topTrailing)
          .frame(width: 32, height: 32)
        ModifierKeyIcon(key: .option, alignment: .topLeading)
          .frame(width: 32, height: 32)
      }
      HStack {
        ModifierKeyIcon(key: .command, alignment: .topTrailing)
          .frame(width: 48, height: 56 / 2)
        ModifierKeyIcon(key: .command, alignment: .topLeading)
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
      Image(systemName: "shield.lefthalf.filled")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 64, height: 64)
      Text("Privacy First")
    }
  }
}

private struct KeyboardCowboyView: View {
  var body: some View {
    HStack(spacing: 16) {
      Image.init(.applicationIcon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 128)
      VStack(alignment: .leading) {
        Group {
          Text("Keyboard")
          Text("Cowboy")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .font(.system(size: 48, design: .rounded))
      .padding(16)
    }
  }
}

private struct WindowManagementView: View {
  let size: CGSize

  init(_ size: CGSize) {
    self.size = size
  }

  var body: some View {
    VStack(spacing: 16) {
      Rectangle()
        .fill(
          LinearGradient(stops: [
            .init(color: Color(nsColor: .white), location: 0.0),
            .init(color: Color(nsColor: .white.withSystemEffect(.disabled)), location: 1.0),
          ], startPoint: .topLeading, endPoint: .bottom)
        )
        .overlay { iconOverlay().opacity(0.5) }
        .overlay(alignment: .topLeading) {
          HStack(alignment: .top, spacing: 0) {
            MinimizeAllWindowTrafficLightsView(size)
            Rectangle()
              .fill(.white)
              .frame(maxWidth: .infinity)
              .overlay { iconOverlay().opacity(0.5) }
          }
        }
        .iconShape(size.width * 0.7)
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

      Text("Window Mangement")
        .font(.system(size: 18, design: .rounded))
    }
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
      .frame(minWidth: 185, minHeight: 156)
      .overlay {
        UIElementIconGradientView()
      }
      .overlay {
        Text("UI Scripting")
          .font(.system(size: 24, design: .rounded))
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .frame(height: 156)
  }
}

#Preview {
  PromoView()
}
