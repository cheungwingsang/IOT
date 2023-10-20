//
//  BeaconView.swift
//  IOT
//
//  Created by Leo Cheung on 20/10/2023.
//

import SwiftUI
import CoreLocation

struct BeaconView: View {
    @ObservedObject var detector = BeaconDetector()
    @State private var isScanning: Bool = false
    
    var body: some View {
        List {
            Section(header: Text("Monitoring")) {
                Text(detector.status)
            }
            Section(header: Text("Ranging")) {
                ForEach(detector.rangedBeacons) { beacon in
                    HStack{
                        Text("Major: \(beacon.major)")
                        Spacer()
                        Text("Minor: \(beacon.minor)")
                        Spacer()
                        Text("Proximity: \(beacon.proximity.stringValue)")
                    }
                }
            }
            Section(header: Text("Control")) {
                Toggle("Scan", isOn: $isScanning)
                    .onChange(of: isScanning) { value in
                        if value == true {
                            detector.startScanning()
                        } else {
                            detector.stopScanning()
                        }
                    }
                    .padding()

            }
        }
    }
}

#Preview {
    BeaconView()
}

class BeaconDetector: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    let uuid = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")
    var beaconRegion: CLBeaconRegion?
    @Published var status = "Initialized"
    
    var constraint: CLBeaconIdentityConstraint?
    @Published var rangedBeacons: [CLBeacon] = []
    
    var locationManager = CLLocationManager()

    override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
        beaconRegion = CLBeaconRegion(uuid: uuid!, identifier: "M5StickC beacons");
        
        constraint = CLBeaconIdentityConstraint(uuid: uuid!)
    }
    
    
    func startScanning() {
        locationManager.startMonitoring(for: beaconRegion!)
        status = "Scanning started"
    }

    func stopScanning() {
        locationManager.stopMonitoring(for: beaconRegion!)
        status = "Scanning stopped"
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        status = "Entered \(region.identifier) region."
        locationManager.startRangingBeacons(satisfying: constraint!)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        status = "Left \(region.identifier) region."
        
        locationManager.stopRangingBeacons(satisfying: constraint!)
        rangedBeacons = []
        
    }
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        rangedBeacons = beacons
    }
}
extension CLBeacon: Identifiable {}

extension CLProximity {
    
    var stringValue: String {
        switch self {
        case .unknown:
            return "unknown"
        case .immediate:
            return "immediate"
        case .near:
            return "near"
        case .far:
            return "far"
        @unknown default:
            return "unknown"
        }
    }
}
