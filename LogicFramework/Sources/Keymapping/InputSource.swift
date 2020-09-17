import Foundation
import Carbon

/// Based on: https://github.com/Clipy/Sauce

public final class InputSource: Hashable {
  public let id: String
  public let modeID: String?
  public let isASCIICapable: Bool
  public let isEnableCapable: Bool
  public let isSelectCapable: Bool
  public let isEnabled: Bool
  public let isSelected: Bool
  public let localizedName: String?
  public let source: TISInputSource

  init(source: TISInputSource) {
    self.id = source.value(forProperty: kTISPropertyInputSourceID, type: String.self)!
    self.modeID = source.value(forProperty: kTISPropertyInputModeID, type: String.self)
    self.isASCIICapable = source.value(forProperty: kTISPropertyInputSourceIsASCIICapable,
                                       type: Bool.self,
                                       defaultValue: false)
    self.isEnableCapable = source.value(forProperty: kTISPropertyInputSourceIsEnableCapable,
                                        type: Bool.self,
                                        defaultValue: false)
    self.isSelectCapable = source.value(forProperty: kTISPropertyInputSourceIsSelectCapable,
                                        type: Bool.self,
                                        defaultValue: false)
    self.isEnabled = source.value(forProperty: kTISPropertyInputSourceIsEnabled,
                                  type: Bool.self,
                                  defaultValue: false)
    self.isSelected = source.value(forProperty: kTISPropertyInputSourceIsSelected,
                                   type: Bool.self,
                                   defaultValue: false)
    self.localizedName = source.value(forProperty: kTISPropertyLocalizedName,
                                      type: String.self)
    self.source = source
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(modeID)
  }

  public static func == (lhs: InputSource, rhs: InputSource) -> Bool {
    return lhs.id == rhs.id && lhs.modeID == rhs.modeID
  }
}
