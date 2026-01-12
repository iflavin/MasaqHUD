import Foundation
import SystemConfiguration
import Network
import CoreWLAN

struct WiFiInfo {
    let ssid: String
    let signalStrength: Int
    let bssid: String
}

struct NetworkUsage {
    let localIP: String
    let publicIP: String
    let bytesIn: UInt64
    let bytesOut: UInt64
    let bytesInPerSec: Double
    let bytesOutPerSec: Double
}

final class NetworkMetrics {
    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var previousTimestamp: Date?
    private var cachedPublicIP: String = "Disabled"
    private var publicIPLastFetch: Date?
    private let publicIPRefreshInterval: TimeInterval = 300

    /// Set to true to enable public IP fetching (requires network access)
    var enablePublicIP: Bool = false {
        didSet {
            if enablePublicIP && !oldValue {
                cachedPublicIP = "..."
                fetchPublicIPAsync()
            } else if !enablePublicIP {
                cachedPublicIP = "Disabled"
            }
        }
    }

    /// Optional interface to filter by (e.g., "en0"). If nil, aggregates all en* interfaces.
    var filterInterface: String?

    init() {
        // Public IP disabled by default
    }

    func getUsage() -> NetworkUsage {
        let localIP = getLocalIP()
        let (bytesIn, bytesOut) = getNetworkBytes()

        var bytesInPerSec: Double = 0
        var bytesOutPerSec: Double = 0

        let now = Date()
        if let prevTime = previousTimestamp {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 {
                let inDiff = bytesIn >= previousBytesIn ? bytesIn - previousBytesIn : 0
                let outDiff = bytesOut >= previousBytesOut ? bytesOut - previousBytesOut : 0
                bytesInPerSec = Double(inDiff) / elapsed
                bytesOutPerSec = Double(outDiff) / elapsed
            }
        }

        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
        previousTimestamp = now

        // Refresh public IP periodically if enabled
        if enablePublicIP {
            if let lastFetch = publicIPLastFetch,
               now.timeIntervalSince(lastFetch) > publicIPRefreshInterval {
                fetchPublicIPAsync()
            }
        }

        return NetworkUsage(
            localIP: localIP,
            publicIP: cachedPublicIP,
            bytesIn: bytesIn,
            bytesOut: bytesOut,
            bytesInPerSec: bytesInPerSec,
            bytesOutPerSec: bytesOutPerSec
        )
    }

    private func getLocalIP() -> String {
        var address = "N/A"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return address
        }

        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)

                // If filtering by interface, only use that interface
                let shouldUse: Bool
                if let filterName = filterInterface {
                    shouldUse = (name == filterName)
                } else {
                    shouldUse = (name == "en0" || name == "en1")
                }

                if shouldUse {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                    // If filtering or found en0, stop searching
                    if filterInterface != nil || name == "en0" { break }
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }

        return address
    }

    private func getNetworkBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)

            // Filter by specific interface if set, otherwise aggregate all en* interfaces
            let shouldInclude: Bool
            if let filterName = filterInterface {
                shouldInclude = (name == filterName)
            } else {
                shouldInclude = name.hasPrefix("en")
            }

            if shouldInclude {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalIn += UInt64(networkData.ifi_ibytes)
                    totalOut += UInt64(networkData.ifi_obytes)
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }

        return (totalIn, totalOut)
    }

    private func fetchPublicIPAsync() {
        publicIPLastFetch = Date()

        Task {
            do {
                let url = URL(string: "https://api.ipify.org")!
                let (data, _) = try await URLSession.shared.data(from: url)
                if let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    await MainActor.run {
                        self.cachedPublicIP = ip
                    }
                }
            } catch {
                await MainActor.run {
                    self.cachedPublicIP = "N/A"
                }
            }
        }
    }

    func getWiFiInfo() -> WiFiInfo {
        guard let interface = CWWiFiClient.shared().interface() else {
            return WiFiInfo(ssid: "N/A", signalStrength: 0, bssid: "N/A")
        }

        let ssid = interface.ssid() ?? "N/A"
        let rssi = interface.rssiValue()  // -100 to 0 dBm
        // Convert RSSI to percentage: -100 dBm = 0%, -50 dBm = 100%
        let signal = max(0, min(100, 2 * (rssi + 100)))
        let bssid = interface.bssid() ?? "N/A"

        return WiFiInfo(ssid: ssid, signalStrength: signal, bssid: bssid)
    }
}
