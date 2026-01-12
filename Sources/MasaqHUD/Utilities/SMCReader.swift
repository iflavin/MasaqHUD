import Foundation
import IOKit

struct TemperatureInfo {
    let cpuTemp: Double
    let gpuTemp: Double
}

/// Temperature reader for Apple Silicon Macs
/// Delegates to AppleSiliconThermal for IOHIDEventSystem-based thermal readings
final class SMCReader {
    private let appleSiliconThermal = AppleSiliconThermal()

    func getTemperatures() -> TemperatureInfo {
        return appleSiliconThermal.getTemperatures()
    }
}
