import Cocoa

public protocol HotkeySupplying: AnyObject {
  var hotkeys: Set<Hotkey> { get }
}

public protocol HotkeyControlling: AnyObject {
  var hotkeyHandler: HotkeyHandling { get }
  var delegate: HotkeyControllingDelegate? { get set }
  var notificationCenter: NotificationControlling { get }

  func register(_ hotkey: Hotkey)
  func unregister(_ hotkey: Hotkey)
  func unregisterAll()
}

public protocol HotkeyControllingDelegate: AnyObject {
  func hotkeyControlling(_ controller: HotkeyController, didRegisterKeyboardShortcut: KeyboardShortcut)
  func hotkeyControlling(_ controller: HotkeyController, didInvokeKeyboardShortcut keyboardShortcut: KeyboardShortcut)
  func hotkeyControlling(_ controller: HotkeyController, didUnregisterKeyboardShortcut: KeyboardShortcut)
}

public class HotkeyController: HotkeyControlling, HotkeySupplying, HotkeyHandlerDelegate {
  public weak var delegate: HotkeyControllingDelegate?
  private(set) public var hotkeys = Set<Hotkey>()
  public let hotkeyHandler: HotkeyHandling
  public let notificationCenter: NotificationControlling
  internal static let signature = "Keyboard-Cowboy"

  init(hotkeyHandler: HotkeyHandling,
       notificationCenter: NotificationControlling = NotificationCenter.default) {
    self.hotkeyHandler = hotkeyHandler
    self.notificationCenter = notificationCenter

    hotkeyHandler.hotkeySupplier = self
    hotkeyHandler.delegate = self
    hotkeyHandler.installEventHandler()
    notificationCenter.addObserver(self,
                                   selector: #selector(applicationWillTerminate),
                                   name: NSApplication.willTerminateNotification,
                                   object: nil)
  }

  public func register(_ hotkey: Hotkey) {
    if hotkeyHandler.register(hotkey, withSignature: HotkeyController.signature) {
      hotkeys.insert(hotkey)
      delegate?.hotkeyControlling(self, didRegisterKeyboardShortcut: hotkey.keyboardShortcut)
    } else {
      unregister(hotkey)
    }
  }

  public func unregisterAll() {
    hotkeys.forEach(unregister)
  }

  public func unregister(_ hotkey: Hotkey) {
    hotkeyHandler.unregister(hotkey)
    hotkey.reference = nil
    delegate?.hotkeyControlling(self, didUnregisterKeyboardShortcut: hotkey.keyboardShortcut)
    hotkey.identifier = nil
    hotkeys.remove(hotkey)
  }

  // MARK: Observations

  @objc func applicationWillTerminate() {
    hotkeys.forEach(unregister)
  }

  // MARK: HotkeyHandlerDelegate

  public func hotkeyHandler(_ handler: HotkeyHandling, didInvokeHotkey hotkey: Hotkey) {
    delegate?.hotkeyControlling(self, didInvokeKeyboardShortcut: hotkey.keyboardShortcut)
  }
}
