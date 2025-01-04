import Carbon
import Foundation

extension KeyShortcut {
  var keyCode: Int? {
    switch self.key {
      // Standard ANSI characters
    case "a", "A": kVK_ANSI_A
    case "b", "B": kVK_ANSI_B
    case "c", "C": kVK_ANSI_C
    case "d", "D": kVK_ANSI_D
    case "e", "E": kVK_ANSI_E
    case "f", "F": kVK_ANSI_F
    case "g", "G": kVK_ANSI_G
    case "h", "H": kVK_ANSI_H
    case "i", "I": kVK_ANSI_I
    case "j", "J": kVK_ANSI_J
    case "k", "K": kVK_ANSI_K
    case "l", "L": kVK_ANSI_L
    case "m", "M": kVK_ANSI_M
    case "n", "N": kVK_ANSI_N
    case "o", "O": kVK_ANSI_O
    case "p", "P": kVK_ANSI_P
    case "q", "Q": kVK_ANSI_Q
    case "r", "R": kVK_ANSI_R
    case "s", "S": kVK_ANSI_S
    case "t", "T": kVK_ANSI_T
    case "u", "U": kVK_ANSI_U
    case "v", "V": kVK_ANSI_V
    case "w", "W": kVK_ANSI_W
    case "x", "X": kVK_ANSI_X
    case "y", "Y": kVK_ANSI_Y
    case "z", "Z": kVK_ANSI_Z
    case "0": kVK_ANSI_0
    case "1": kVK_ANSI_1
    case "2": kVK_ANSI_2
    case "3": kVK_ANSI_3
    case "4": kVK_ANSI_4
    case "5": kVK_ANSI_5
    case "6": kVK_ANSI_6
    case "7": kVK_ANSI_7
    case "8": kVK_ANSI_8
    case "9": kVK_ANSI_9
    case "`", "~": kVK_ANSI_Grave
    case "-", "_": kVK_ANSI_Minus
    case "=", "+": kVK_ANSI_Equal
    case "[", "{": kVK_ANSI_LeftBracket
    case "]", "}": kVK_ANSI_RightBracket
    case "\\", "|": kVK_ANSI_Backslash
    case ";", ":": kVK_ANSI_Semicolon
    case "'", "\"": kVK_ANSI_Quote
    case ",", "<": kVK_ANSI_Comma
    case ".", ">": kVK_ANSI_Period
    case "/", "?": kVK_ANSI_Slash
    case " ", "Space", "SPACE": kVK_Space

      // Modifier keys
    case "Tab", "TAB", "⇥": kVK_Tab
    case "Escape", "ESCAPE", "⎋": kVK_Escape

      // Special keys
    case "ForwardDelete", "FORWARDDELETE", "⌦": kVK_ForwardDelete
    case "Help", "HELP", "?⃝": kVK_Help
    case "KeypadEnter", "KEYPADENTER", "⌤": kVK_ANSI_KeypadEnter
    case "Return", "RETURN", "⏎": kVK_Return
    case "Delete", "DELETE", "⌫": kVK_Delete
    case "Home", "HOME", "↖": kVK_Home
    case "End", "END", "↘": kVK_End
    case "PageUp", "PAGEUP", "⇞": kVK_PageUp
    case "PageDown", "PAGEDOWN", "⇟": kVK_PageDown
    case "LeftArrow", "LEFTARROW", "←": kVK_LeftArrow
    case "RightArrow", "RIGHTARROW", "→": kVK_RightArrow
    case "UpArrow", "UPARROW", "↑": kVK_UpArrow
    case "DownArrow", "DOWNARROW", "↓": kVK_DownArrow
    case "F1": kVK_F1
    case "F2": kVK_F2
    case "F3": kVK_F3
    case "F4": kVK_F4
    case "F5": kVK_F5
    case "F6": kVK_F6
    case "F7": kVK_F7
    case "F8": kVK_F8
    case "F9": kVK_F9
    case "F10": kVK_F10
    case "F11": kVK_F11
    case "F12": kVK_F12
    case "F13": kVK_F13
    case "F14": kVK_F14
    case "F15": kVK_F15
    case "F16": kVK_F16
    case "F17": kVK_F17
    case "F18": kVK_F18
    case "F19": kVK_F19
    case "F20": kVK_F20

      // Norwegian-specific characters
    case "å", "Å": kVK_ANSI_Grave        // Typically backtick/tilde key
    case "ø", "Ø": kVK_ANSI_Semicolon    // Typically semicolon/colon key
    case "æ", "Æ": kVK_ANSI_Quote        // Typically quote/double-quote key

      // Swedish-specific characters
    case "ä", "Ä": kVK_ANSI_Quote        // Same key as "æ/Æ" in Norwegian
    case "ö", "Ö": kVK_ANSI_Semicolon    // Same key as "ø/Ø" in Norwegian

    default: nil
    }
  }

  // Standard ANSI characters
  static var a: KeyShortcut { KeyShortcut(key: "a") }
  static var b: KeyShortcut { KeyShortcut(key: "b") }
  static var c: KeyShortcut { KeyShortcut(key: "c") }
  static var d: KeyShortcut { KeyShortcut(key: "d") }
  static var e: KeyShortcut { KeyShortcut(key: "e") }
  static var f: KeyShortcut { KeyShortcut(key: "f") }
  static var g: KeyShortcut { KeyShortcut(key: "g") }
  static var h: KeyShortcut { KeyShortcut(key: "h") }
  static var i: KeyShortcut { KeyShortcut(key: "i") }
  static var j: KeyShortcut { KeyShortcut(key: "j") }
  static var k: KeyShortcut { KeyShortcut(key: "k") }
  static var l: KeyShortcut { KeyShortcut(key: "l") }
  static var m: KeyShortcut { KeyShortcut(key: "m") }
  static var n: KeyShortcut { KeyShortcut(key: "n") }
  static var o: KeyShortcut { KeyShortcut(key: "o") }
  static var p: KeyShortcut { KeyShortcut(key: "p") }
  static var q: KeyShortcut { KeyShortcut(key: "q") }
  static var r: KeyShortcut { KeyShortcut(key: "r") }
  static var s: KeyShortcut { KeyShortcut(key: "s") }
  static var t: KeyShortcut { KeyShortcut(key: "t") }
  static var u: KeyShortcut { KeyShortcut(key: "u") }
  static var v: KeyShortcut { KeyShortcut(key: "v") }
  static var w: KeyShortcut { KeyShortcut(key: "w") }
  static var x: KeyShortcut { KeyShortcut(key: "x") }
  static var y: KeyShortcut { KeyShortcut(key: "y") }
  static var z: KeyShortcut { KeyShortcut(key: "z") }
  static var zero: KeyShortcut { KeyShortcut(key: "0") }
  static var one: KeyShortcut { KeyShortcut(key: "1") }
  static var two: KeyShortcut { KeyShortcut(key: "2") }
  static var three: KeyShortcut { KeyShortcut(key: "3") }
  static var four: KeyShortcut { KeyShortcut(key: "4") }
  static var five: KeyShortcut { KeyShortcut(key: "5") }
  static var six: KeyShortcut { KeyShortcut(key: "6") }
  static var seven: KeyShortcut { KeyShortcut(key: "7") }
  static var eight: KeyShortcut { KeyShortcut(key: "8") }
  static var nine: KeyShortcut { KeyShortcut(key: "9") }
  static var grave: KeyShortcut { KeyShortcut(key: "`") }
  static var minus: KeyShortcut { KeyShortcut(key: "-") }
  static var equal: KeyShortcut { KeyShortcut(key: "=") }
  static var leftBracket: KeyShortcut { KeyShortcut(key: "[") }
  static var rightBracket: KeyShortcut { KeyShortcut(key: "]") }
  static var backslash: KeyShortcut { KeyShortcut(key: "\\") }
  static var semicolon: KeyShortcut { KeyShortcut(key: ";") }
  static var quote: KeyShortcut { KeyShortcut(key: "'") }
  static var comma: KeyShortcut { KeyShortcut(key: ",") }
  static var period: KeyShortcut { KeyShortcut(key: ".") }
  static var slash: KeyShortcut { KeyShortcut(key: "/") }
  static var space: KeyShortcut { KeyShortcut(key: " ") }

  // Modifier keys
  static var tab: KeyShortcut { KeyShortcut(key: "⇥") }
  static var escape: KeyShortcut { KeyShortcut(key: "⎋") }

  // Special keys
  static var forwardDelete: KeyShortcut { KeyShortcut(key: "⌦") }
  static var help: KeyShortcut { KeyShortcut(key: "?⃝") }
  static var keypadEnter: KeyShortcut { KeyShortcut(key: "⌤") }
  static var returnKey: KeyShortcut { KeyShortcut(key: "⏎") }
  static var delete: KeyShortcut { KeyShortcut(key: "⌫") }
  static var home: KeyShortcut { KeyShortcut(key: "↖") }
  static var end: KeyShortcut { KeyShortcut(key: "↘") }
  static var pageUp: KeyShortcut { KeyShortcut(key: "⇞") }
  static var pageDown: KeyShortcut { KeyShortcut(key: "⇟") }
  static var leftArrow: KeyShortcut { KeyShortcut(key: "←") }
  static var rightArrow: KeyShortcut { KeyShortcut(key: "→") }
  static var upArrow: KeyShortcut { KeyShortcut(key: "↑") }
  static var downArrow: KeyShortcut { KeyShortcut(key: "↓") }

  // Function keys
  static var f1: KeyShortcut { KeyShortcut(key: "F1") }
  static var f2: KeyShortcut { KeyShortcut(key: "F2") }
  static var f3: KeyShortcut { KeyShortcut(key: "F3") }
  static var f4: KeyShortcut { KeyShortcut(key: "F4") }
  static var f5: KeyShortcut { KeyShortcut(key: "F5") }
  static var f6: KeyShortcut { KeyShortcut(key: "F6") }
  static var f7: KeyShortcut { KeyShortcut(key: "F7") }
  static var f8: KeyShortcut { KeyShortcut(key: "F8") }
  static var f9: KeyShortcut { KeyShortcut(key: "F9") }
  static var f10: KeyShortcut { KeyShortcut(key: "F10") }
  static var f11: KeyShortcut { KeyShortcut(key: "F11") }
  static var f12: KeyShortcut { KeyShortcut(key: "F12") }
  static var f13: KeyShortcut { KeyShortcut(key: "F13") }
  static var f14: KeyShortcut { KeyShortcut(key: "F14") }
  static var f15: KeyShortcut { KeyShortcut(key: "F15") }
  static var f16: KeyShortcut { KeyShortcut(key: "F16") }
  static var f17: KeyShortcut { KeyShortcut(key: "F17") }
  static var f18: KeyShortcut { KeyShortcut(key: "F18") }
  static var f19: KeyShortcut { KeyShortcut(key: "F19") }
  static var f20: KeyShortcut { KeyShortcut(key: "F20") }

  // Norwegian-specific characters
  static var å: KeyShortcut { KeyShortcut(key: "å") }
  static var ø: KeyShortcut { KeyShortcut(key: "ø") }
  static var æ: KeyShortcut { KeyShortcut(key: "æ") }

  // Swedish-specific characters
  static var ä: KeyShortcut { KeyShortcut(key: "ä") }
  static var ö: KeyShortcut { KeyShortcut(key: "ö") }
}
