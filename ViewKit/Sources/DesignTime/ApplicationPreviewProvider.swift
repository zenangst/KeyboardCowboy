import ModelKit

final class ApplicationPreviewProvider: StateController {
  let state: [Application] = [
    Application.calendar(),
    Application.finder(),
    Application.messages(),
    Application.music(),
  ]
}
