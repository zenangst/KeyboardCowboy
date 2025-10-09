import Bonzai
import Inject
import SwiftUI

@MainActor
final class CapsuleNotificationPublisher: ObservableObject {
  enum State: Equatable {
    case idle
    case running
    case failure
    case success
    case warning

    var foregroundColor: Color {
      switch self {
      case .running, .idle: .white
      case .failure: Color(.systemRed.withSystemEffect(.deepPressed))
      case .warning: Color(.systemOrange.withSystemEffect(.deepPressed))
      case .success: Color(.controlAccentColor.withSystemEffect(.deepPressed))
      }
    }

    var borderColor: Color {
      switch self {
      case .running, .idle: .gray
      case .failure: Color(.systemRed.withSystemEffect(.deepPressed))
      case .warning: Color(.systemOrange.withSystemEffect(.deepPressed))
      case .success: Color(.controlAccentColor.withSystemEffect(.deepPressed))
      }
    }

    var backgroundColor: Color {
      switch self {
      case .running, .idle: .black
      case .failure: Color.systemRed.blended(withFraction: 0.85, of: .black)
      case .warning: Color.systemOrange.blended(withFraction: 0.85, of: .black)
      case .success: Color(nsColor: .controlAccentColor).blended(withFraction: 0.45, of: .black)
      }
    }
  }

  var id: String
  @Published var text: String
  @Published var state: State

  init(text: String = "", id: String, state: State = .running) {
    self.id = id
    self.text = text
    self.state = state
  }

  @MainActor
  func publish(_ text: String, id: String, state: State) {
    self.id = id
    self.state = state
    self.text = text
  }
}

struct CapsuleNotificationView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: CapsuleNotificationPublisher
  @Namespace var namespace

  init(publisher: CapsuleNotificationPublisher) {
    self.publisher = publisher
  }

  var body: some View {
    TextContainerView()
      .animation(.none, value: publisher.state)
      .font(.system(.title2, design: .rounded, weight: .regular))
      .padding(.leading, publisher.state == .running ? 24 : 0)
      .foregroundStyle(publisher.state.foregroundColor)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        ZStack {
          Capsule(style: .continuous)
            .stroke(publisher.state.borderColor.opacity(0.2), lineWidth: 2)
            .padding(1)

          Capsule(style: .continuous)
            .stroke(publisher.state.borderColor.opacity(0.05), lineWidth: 2)
        }
        .opacity(publisher.state == .idle ? 0 : 1)
        .animation(.smooth(duration: 0.1), value: publisher.state),
      )
      .background(
        Capsule(style: .continuous)
          .fill(
            LinearGradient(stops: [
              .init(color: publisher.state.backgroundColor.opacity(0.8), location: 0),
              .init(color: publisher.state.backgroundColor.opacity(0.9), location: 0.8),
            ], startPoint: .top, endPoint: .bottom),
          )
          .opacity(publisher.state == .idle ? 0 : 1)
          .animation(.smooth(duration: 0.1), value: publisher.state),
      )
      .frame(minWidth: 128, maxWidth: .infinity)
      .opacity(publisher.state == .idle ? 0 : 1)
      .animation(.smooth(duration: 0.275), value: publisher.state)
      .environmentObject(publisher)
  }
}

private struct TextContainerView: View {
  @EnvironmentObject var publisher: CapsuleNotificationPublisher

  var body: some View {
    Group {
      if !publisher.text.isEmpty {
        AnimatedText(text: publisher.text)
      } else {
        Text(" ")
      }
    }
  }
}

private struct AnimatedText: View {
  let text: String

  @State private var previousText: String = ""
  @State private var animatingIndices: Set<Int> = []

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(text.enumerated()), id: \.offset) { idx, char in
        AnimatedCharacterView(
          char: char,
          index: idx,
          shouldAnimate: animatingIndices.contains(idx),
        )
        .id("\(idx)-\(char)")
      }
    }
    .onChange(of: text) { newValue in
      let newChars = Array(newValue)
      let oldChars = Array(previousText)

      var changed = Set<Int>()
      let count = max(newChars.count, oldChars.count)
      for i in 0 ..< count {
        let oldChar = i < oldChars.count ? oldChars[i] : nil
        let newChar = i < newChars.count ? newChars[i] : nil
        if oldChar != newChar {
          changed.insert(i)
        }
      }
      animatingIndices = changed
      previousText = newValue

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        animatingIndices = []
      }
    }
    .onAppear {
      previousText = text
      animatingIndices = []
    }
  }
}

private struct AnimatedCharacterView: View {
  let char: Character
  let index: Int
  let shouldAnimate: Bool

  @State private var animating = false

  var body: some View {
    Text(String(char))
      .opacity(animating ? 1 : 0)
      .offset(y: animating ? 0 : -10)
      .animation(
        shouldAnimate ?
          .smooth.delay(Double(index) * 0.001) : .none,
        value: animating,
      )
      .onAppear {
        animating = true
      }
      .onChange(of: shouldAnimate) { newValue in
        if newValue {
          animating = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            animating = true
          }
        }
      }
  }
}

#Preview {
  let dynamicPublisher = CapsuleNotificationPublisher(text: "Running…", id: UUID().uuidString)

  return VStack(spacing: 4) {
    CapsuleNotificationView(publisher: dynamicPublisher)
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          dynamicPublisher.text = "Workflow successful."
          dynamicPublisher.state = .success
        }
      }
    ZenDivider()
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Running…", id: UUID().uuidString, state: .running))
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Workflow successful.", id: UUID().uuidString, state: .failure))
    CapsuleNotificationView(publisher: CapsuleNotificationPublisher(text: "Workflow successful.", id: UUID().uuidString, state: .success))
  }
  .padding(10)
}
