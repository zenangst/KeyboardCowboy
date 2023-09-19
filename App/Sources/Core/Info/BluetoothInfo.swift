import Foundation
import CoreBluetooth

final class BluetoothInfo: NSObject, CBCentralManagerDelegate {
  private var centralManager: CBCentralManager!

  static let shared = BluetoothInfo()

  private override init() {
    super.init()
    self.centralManager = CBCentralManager(delegate: self, queue: nil)
    centralManager.delegate = self
  }

  func getConnectedDevices() -> [CBPeripheral] {
    var connectedDevices: [CBPeripheral] = []

    let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID]())

    connectedDevices = connectedPeripherals

    return connectedDevices
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print(#function)
 }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//    print(#function)
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    return
//    switch central.state {
//    case .poweredOn:
//
//      let connectedDevices = getConnectedDevices()
//
//      print("poweredOn")
//      print(connectedDevices)
//
//    case .poweredOff:
//      print("poweredOff")
//    case .resetting:
//      print("resetting")
//    case .unauthorized:
//      print("unauthorized")
//    case .unsupported:
//      print("unsupported")
//    case .unknown:
//      print("unknown")
//    }
  }
}
