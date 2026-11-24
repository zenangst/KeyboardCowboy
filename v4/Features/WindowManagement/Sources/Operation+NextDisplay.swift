import CoreGraphics

extension Operation {
  struct NextDisplay: Sendable {
    let displays: [WindowManagement.Display]

    func requestedFrame(for original: CGRect) -> CGRect? {
      guard displays.count > 1,
            let current = WindowManagement.displayIndex(for: original, on: displays) else { return nil }
      for offset in 1 ..< displays.count {
        let display = displays[(current + offset) % displays.count]
        guard display.bounds != displays[current].bounds,
              let usable = WindowManagement.usableBounds(of: display) else { continue }
        return WindowManagement.centeredFrame(original, in: usable)
      }
      return nil
    }
  }
}
