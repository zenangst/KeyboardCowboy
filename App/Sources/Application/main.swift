import Cocoa
let appDelegate = AppDelegate()
let mainMenu = AppMenu(title: "MainMenu")
NSApplication.shared.delegate = appDelegate
NSApplication.shared.mainMenu = mainMenu
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
