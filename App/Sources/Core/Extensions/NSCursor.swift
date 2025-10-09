import Cocoa
import CoreGraphics

extension NSCursor {
  enum Interpolation {
    case spring
    case easeIn
    case easeOut
    case easeInOut
  }

  private nonisolated(unsafe) static var currentWorkItem: DispatchWorkItem?

  static func moveCursor(from startPoint: CGPoint = NSEvent.mouseLocation.mainDisplayFlipped, to point: CGPoint, duration: TimeInterval = 0, interpolation: Interpolation = .easeInOut) {
    currentWorkItem?.cancel() // Cancel any ongoing animation
    if duration > 0 {
      animateMouseCursor(to: point, startPoint: startPoint, duration: duration, interpolation: interpolation)
    } else {
      CGWarpMouseCursorPosition(point)
    }
  }

  private static func animateMouseCursor(to targetPoint: CGPoint, startPoint: CGPoint, duration: TimeInterval, interpolation: Interpolation) {
    let steps = 100
    let stepDuration = duration / Double(steps)

    // Define a control point for the Bézier curve
    let controlPoint = CGPoint(x: (startPoint.x + targetPoint.x) / 2, y: min(startPoint.y, targetPoint.y) - 100)

    let workItem = DispatchWorkItem {
      for step in 0 ... steps {
        let t = Double(step) / Double(steps)
        let interpolatedT: Double = switch interpolation {
        case .spring:
          springInterpolation(t)
        case .easeIn:
          easeInInterpolation(t)
        case .easeOut:
          easeOutInterpolation(t)
        case .easeInOut:
          easeInOutInterpolation(t)
        }

        // Calculate the Bézier curve point
        let newX = pow(1 - interpolatedT, 2) * startPoint.x + 2 * (1 - interpolatedT) * interpolatedT * controlPoint.x + pow(interpolatedT, 2) * targetPoint.x
        let newY = pow(1 - interpolatedT, 2) * startPoint.y + 2 * (1 - interpolatedT) * interpolatedT * controlPoint.y + pow(interpolatedT, 2) * targetPoint.y

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
          if currentWorkItem?.isCancelled == false {
            let point = CGPoint(x: newX, y: newY)
            let mouseEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .center)
            mouseEvent?.post(tap: .cghidEventTap)
          }
        }
      }
    }

    currentWorkItem = workItem
    DispatchQueue.main.async(execute: workItem)
  }

  private static func springInterpolation(_ t: Double) -> Double {
    1 - pow(2.71828, -6 * t) * cos(12 * t)
  }

  private static func easeInInterpolation(_ t: Double) -> Double {
    t * t
  }

  private static func easeOutInterpolation(_ t: Double) -> Double {
    t * (2 - t)
  }

  private static func easeInOutInterpolation(_ t: Double) -> Double {
    t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
  }
}
