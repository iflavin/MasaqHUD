import Foundation
import IOBluetooth

struct BluetoothDeviceInfo {
    let name: String
    let address: String
    let isConnected: Bool
}

struct BluetoothInfo {
    let connectedCount: Int
    let devices: [BluetoothDeviceInfo]
    let isPoweredOn: Bool
}

final class BluetoothMetrics {
    private var cachedInfo: BluetoothInfo?
    private var lastFetchTime: Date?
    private let cacheTTL: TimeInterval = 5

    func getInfo() -> BluetoothInfo {
        if let cachedInfo, let lastFetchTime,
           Date().timeIntervalSince(lastFetchTime) < cacheTTL {
            return cachedInfo
        }

        let info = fetchInfo()
        cachedInfo = info
        lastFetchTime = Date()
        return info
    }

    private func fetchInfo() -> BluetoothInfo {
        // Check if Bluetooth is powered on
        guard let hostController = IOBluetoothHostController.default() else {
            return BluetoothInfo(connectedCount: 0, devices: [], isPoweredOn: false)
        }

        let isPoweredOn = hostController.powerState == kBluetoothHCIPowerStateON

        guard isPoweredOn else {
            return BluetoothInfo(connectedCount: 0, devices: [], isPoweredOn: false)
        }

        // Get paired devices
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return BluetoothInfo(connectedCount: 0, devices: [], isPoweredOn: true)
        }

        var connectedDevices: [BluetoothDeviceInfo] = []

        for device in pairedDevices {
            if device.isConnected() {
                let deviceInfo = BluetoothDeviceInfo(
                    name: device.name ?? "Unknown",
                    address: device.addressString ?? "N/A",
                    isConnected: true
                )
                connectedDevices.append(deviceInfo)
            }
        }

        return BluetoothInfo(
            connectedCount: connectedDevices.count,
            devices: connectedDevices,
            isPoweredOn: true
        )
    }
}
