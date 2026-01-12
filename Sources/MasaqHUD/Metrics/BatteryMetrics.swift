import Foundation
import IOKit.ps

struct BatteryInfo {
    let percent: Int
    let status: String          // "Charging", "Discharging", "Full", "Not Charging"
    let timeRemaining: String   // "1:30" or "Calculating..." or "N/A"
    let powerDraw: Double       // Watts (positive = charging, negative = discharging)
    let isPresent: Bool
    let cycleCount: Int
    let health: Int             // Percentage of original capacity
}

final class BatteryMetrics {

    func getInfo() -> BatteryInfo {
        // Get power source info
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty,
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return BatteryInfo(
                percent: 0,
                status: "N/A",
                timeRemaining: "N/A",
                powerDraw: 0,
                isPresent: false,
                cycleCount: 0,
                health: 0
            )
        }

        // Battery present check
        let isPresent = info[kIOPSIsPresentKey] as? Bool ?? false
        guard isPresent else {
            return BatteryInfo(
                percent: 0,
                status: "No Battery",
                timeRemaining: "N/A",
                powerDraw: 0,
                isPresent: false,
                cycleCount: 0,
                health: 0
            )
        }

        // Current capacity percentage
        let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
        let percent = maxCapacity > 0 ? (currentCapacity * 100) / maxCapacity : 0

        // Charging status
        let isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
        let isPluggedIn = info[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        let isFullyCharged = info[kIOPSIsChargedKey] as? Bool ?? false

        let status: String
        if isFullyCharged {
            status = "Full"
        } else if isCharging {
            status = "Charging"
        } else if isPluggedIn {
            status = "Not Charging"
        } else {
            status = "Discharging"
        }

        // Time remaining
        let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int ?? -1
        let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int ?? -1

        let timeRemaining: String
        if isCharging && timeToFull > 0 {
            let hours = timeToFull / 60
            let minutes = timeToFull % 60
            timeRemaining = String(format: "%d:%02d", hours, minutes)
        } else if !isCharging && !isPluggedIn && timeToEmpty > 0 {
            let hours = timeToEmpty / 60
            let minutes = timeToEmpty % 60
            timeRemaining = String(format: "%d:%02d", hours, minutes)
        } else if timeToEmpty == -1 || timeToFull == -1 {
            timeRemaining = "Calculating..."
        } else {
            timeRemaining = "N/A"
        }

        // Power draw (amperage * voltage)
        // Note: These may not be available on all systems
        let amperage = getBatteryProperty("CurrentCapacity") ?? 0
        let voltage = getBatteryProperty("Voltage") ?? 0
        var powerDraw = 0.0
        if voltage > 0 {
            // Amperage is in mA, voltage in mV
            powerDraw = (Double(amperage) * Double(voltage)) / 1_000_000.0
        }

        // Cycle count and health from IORegistry
        let cycleCount = getBatteryProperty("CycleCount") ?? 0
        let designCapacity = getBatteryProperty("DesignCapacity") ?? 0
        let actualMaxCapacity = getBatteryProperty("MaxCapacity") ?? designCapacity
        let health = designCapacity > 0 ? (actualMaxCapacity * 100) / designCapacity : 100

        return BatteryInfo(
            percent: percent,
            status: status,
            timeRemaining: timeRemaining,
            powerDraw: powerDraw,
            isPresent: true,
            cycleCount: cycleCount,
            health: health
        )
    }

    private func getBatteryProperty(_ property: String) -> Int? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )

        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any],
              let value = dict[property] as? Int else {
            return nil
        }

        return value
    }
}
