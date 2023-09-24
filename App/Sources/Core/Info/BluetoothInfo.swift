import Foundation
import CoreBluetooth

final class BluetoothInfo: NSObject, CBCentralManagerDelegate {
  static let shared = BluetoothInfo()
  private var central: CBCentralManager!
  @MainActor
  private var peripherals = Set<CBPeripheral>()

  private override init() {
    super.init()
    self.central = CBCentralManager(delegate: self, queue: nil)

  }


  @MainActor
  func listConnectedBluetoothDevices(_ central: CBCentralManager) async -> Set<CBPeripheral> {
    peripherals.removeAll()
    central.scanForPeripherals(withServices: [])
    try? await Task.sleep(for: .seconds(2))
    central.stopScan()
    return peripherals
  }


  // MARK: CBCentralManagerDelegate

  @MainActor
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, 
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
    peripherals.insert(peripheral)
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .unknown:
      print("central.state is .unknown")
    case .resetting:
      print("central.state is .resetting")
    case .unsupported:
      print("central.state is .unsupported")
    case .unauthorized:
      print("central.state is .unauthorized")
    case .poweredOff:
      print("central.state is .poweredOff")
    case .poweredOn:
      print("central.state is .poweredOn")

      Task {
        let results = await listConnectedBluetoothDevices(central)

        for peripheral in results {
          print(peripheral)
        }

        print(results.count)
      }
    @unknown default:
      fatalError("ops!")
    }
  }
}
