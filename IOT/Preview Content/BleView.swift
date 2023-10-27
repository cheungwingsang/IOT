//
//  BleView.swift
//  IOT
//
//  Created by Leo Cheung on 20/10/2023.
//

import SwiftUI
import CoreBluetooth

struct BleView: View {
    @ObservedObject var client = BleClient()
    
    var body: some View {
        List {
            Section(header: Text("Scan and Connect")) {
                Text(client.status)
                Button("Scan and connect", action: client.startScanning )
            }
            Section(header: Text("Heart Rate Measurement")) {
                Text("\(client.heartRateMeasurement) bpm")
                Button("Register heart rate measurement", action:  client.registerHeartRateMeasurement )
            }
            Section(header: Text("Body Sensor Location")) {
                Text(client.bodySensorLocation)
                Button("Read body sensor location", action: client.readBodySensorLocation )
            }
            Section(header: Text("Heart Rate Control Point")) {
                Button("Write 0xC9", action: { client.writeHeartRateControlPoint(Data([0xC9])) } )
                Button("Write 0xBEEF", action: { client.writeHeartRateControlPoint(Data([0xBE, 0xEF])) } )
            }
        }
    }
}
#Preview {
    BleView()
}

class BleClient: NSObject, ObservableObject {
    
    @Published var status = "Inited"
    @Published var heartRateMeasurement: UInt16 = 0
    @Published var bodySensorLocation: String = "Unknown"
    var centralManager: CBCentralManager?
    var heartRateMonitor: CBPeripheral?
    var heartRateMeasurementCharacteristic: CBCharacteristic?
    var bodySensorLocationCharacteristic: CBCharacteristic?
    var heartRateControlPointCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        // TODO: Implement scanning
        centralManager?.scanForPeripherals(withServices: [CBUUID.heartRateServiceUUID], options: nil)
    }
    
    func registerHeartRateMeasurement() {
        guard let characteristic = heartRateMeasurementCharacteristic else { return }
        heartRateMonitor?.setNotifyValue(true, for: characteristic)
    }

    func readBodySensorLocation() {
        guard let characteristic = bodySensorLocationCharacteristic else { return }
        heartRateMonitor?.readValue(for: characteristic)
    }

    func writeHeartRateControlPoint(_ controlPoint: Data) {
        guard let characteristic = heartRateControlPointCharacteristic else { return }
        heartRateMonitor?.writeValue(controlPoint, for: characteristic, type: .withResponse)
    }
    
   
}
extension BleClient: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        status = central.state.stringValue
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        
        print(peripheral);
        status = "Discovered peripheral: \(peripheral)"
        
        heartRateMonitor = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print(peripheral)
        status = "Connected peripheral: \(peripheral)"
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension CBManagerState {
    
    var stringValue: String {
        switch self {
        case .poweredOff:
            return "Bluetooth is currently powered off."
        case .poweredOn:
            return "Bluetooth is currently powered on and available to use."
        case .resetting:
            return "The connection with the system service was momentarily lost."
        case .unauthorized:
            return "The application isn’t authorized to use the Bluetooth low energy role."
        case .unknown:
            return "State is unknown."
        case .unsupported:
            return "This device doesn’t support the Bluetooth low energy central or client role."
        @unknown default:
            return "State is unknown."
        }
    }
}

extension CBUUID {
    
    static public let heartRateServiceUUID = CBUUID(string: "180D")
    static public let heartRateMeasurementUUID = CBUUID(string: "2A37")
    static public let bodySensorLocationUUID = CBUUID(string: "2A38")
    static public let heartRateControlPointUUID = CBUUID(string: "2A39")
}

extension BleClient: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        print(services)
        status = "Discovered services: \(services)"
        
        for service in services {
            
            if (service.uuid == CBUUID.heartRateServiceUUID) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        
        print(characteristics)
        status = "Discovered Characteristics: \(characteristics)"
        
        for characteristic in characteristics {
            
            if (characteristic.uuid == CBUUID.heartRateMeasurementUUID) {
                heartRateMeasurementCharacteristic = characteristic
            }
            
            if (characteristic.uuid == CBUUID.bodySensorLocationUUID) {
                bodySensorLocationCharacteristic = characteristic
            }
            
            if (characteristic.uuid == CBUUID.heartRateControlPointUUID) {
                heartRateControlPointCharacteristic = characteristic
            }
        }
    }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            
            guard let data = characteristic.value else { return }
            
            switch characteristic.uuid {
                
            case CBUUID.heartRateMeasurementUUID:
                
                heartRateMeasurement = UInt16(bigEndian: data.withUnsafeBytes {
                    $0.load(as: UInt16.self)
                })
                
            case CBUUID.bodySensorLocationUUID:
                
                bodySensorLocation = data.bodySensorLocation
                
            default:
                print("Characteristic not handled.")
            }
        }
    
}

extension Data {
    var bodySensorLocation: String {
        
        guard let byte = self.first else { return "Error" }
        
        switch byte {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
}
