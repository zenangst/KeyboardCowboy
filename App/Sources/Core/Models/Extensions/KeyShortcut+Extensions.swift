import Carbon
import Foundation

extension KeyShortcut {
  var keyCode: Int? {
    switch self.key {
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
    case " ": kVK_Space
    case "Space": kVK_Space
    case "SPACE": kVK_Space
    default: nil
    }
  }
}
