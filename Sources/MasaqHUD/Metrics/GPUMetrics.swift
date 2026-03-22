import Foundation
import IOKit

struct GPUUsage {
    let name: String
    let utilizationPercent: Double
    let temperature: Double
}

final class GPUMetrics {
    private let smcReader: SMCReader
    private var cachedGPUName: String?

    init(smcReader: SMCReader) {
        self.smcReader = smcReader
    }

    func getUsage() -> GPUUsage {
        let (name, utilization) = getGPUNameAndUtilization()
        let temps = smcReader.getTemperatures()

        return GPUUsage(
            name: name,
            utilizationPercent: utilization,
            temperature: temps.gpuTemp
        )
    }

    /// Single IORegistry lookup that returns both GPU name and utilization.
    private func getGPUNameAndUtilization() -> (name: String, utilization: Double) {
        // Return cached name with fresh utilization if name is already known
        // (GPU name never changes at runtime)

        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AGXAccelerator")

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return (cachedGPUName ?? "Unknown GPU", 0.0)
        }

        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else {
            return (cachedGPUName ?? "Unknown GPU", 0.0)
        }

        defer { IOObjectRelease(service) }

        // Cache GPU name on first successful lookup
        if cachedGPUName == nil {
            cachedGPUName = "Apple GPU"
        }

        let utilization = extractUtilization(from: service)
        return (cachedGPUName!, utilization)
    }

    /// Extract GPU utilization percentage from an IORegistry service entry.
    private func extractUtilization(from service: io_object_t) -> Double {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let properties = props?.takeRetainedValue() as? [String: Any],
              let perfStats = properties["PerformanceStatistics"] as? [String: Any] else {
            return 0.0
        }

        if let utilization = perfStats["Device Utilization %"] as? NSNumber {
            return utilization.doubleValue
        }
        if let utilization = perfStats["GPU Activity(%)"] as? NSNumber {
            return utilization.doubleValue
        }
        return 0.0
    }
}
