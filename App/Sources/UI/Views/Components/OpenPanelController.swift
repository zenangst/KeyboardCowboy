import Combine
import Cocoa

public enum OpenPanelAction {
  case selectFile(types: [String], handler: (String) -> Void)
  case selectFolder(allowMultipleSelections: Bool, handler: (String) -> Void)
}

@MainActor
final class OpenPanelController: NSObject, ObservableObject, NSOpenSavePanelDelegate {
  @Published var state: String = ""
  var fileExtensions: [String] = []

  func perform(_ action: OpenPanelAction) {
    let panel = NSOpenPanel()
    panel.delegate = self
    panel.resolvesAliases = true
    let responseHandler: (String) -> Void

    switch action {
    case .selectFile(let fileExtensions, let handler):
      self.fileExtensions = fileExtensions
      panel.allowsOtherFileTypes = !fileExtensions.isEmpty
      responseHandler = handler
      panel.canChooseFiles = true
      panel.canChooseDirectories = true
    case .selectFolder(let allowsMultipleSelection, let handler):
      panel.canChooseFiles = false
      panel.canChooseDirectories = true
      panel.allowsMultipleSelection = allowsMultipleSelection
      responseHandler = handler
    }

    let response = panel.runModal()

    guard response == .OK, panel.url?.path != nil else { return }

    panel.urls.forEach { url in
      responseHandler(url.path)
    }
  }

  // MARK: NSOpenSavePanelDelegate

  func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
    guard !fileExtensions.isEmpty else { return true }

    let pathExtension = (url.path as NSString).pathExtension

    return pathExtension.isEmpty || fileExtensions.contains(pathExtension)
  }
}
