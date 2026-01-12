import Foundation
import IOKit

struct GPUUsage {
    let name: String
    let utilizationPercent: Double
    let temperature: Double
}

final class GPUMetrics {
    private let smcReader: SMCReader

    init(smcReader: SMCReader) {
        self.smcReader = smcReader
    }

    func getUsage() -> GPUUsage {
        let utilization = getGPUUtilization()
        let temps = smcReader.getTemperatures()

        return GPUUsage(
            name: getGPUName(),
            utilizationPercent: utilization,
            temperature: temps.gpuTemp
        )
    }

    private func getGPUName() -> String {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AGXAccelerator")

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return "Unknown GPU"
        }

        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        if service != 0 {
            defer { IOObjectRelease(service) }
            return "Apple GPU"
        }

        return "Unknown GPU"
    }

    private func getGPUUtilization() -> Double {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("AGXAccelerator")

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return 0.0
        }

        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else {
            return 0.0
        }

        defer { IOObjectRelease(service) }

        if let props = getServiceProperties(service) {
            if let perfStats = props["PerformanceStatistics"] as? [String: Any] {
                if let utilization = perfStats["Device Utilization %"] as? NSNumber {
                    return utilization.doubleValue
                }
                if let utilization = perfStats["GPU Activity(%)"] as? NSNumber {
                    return utilization.doubleValue
                }
            }
        }

        return 0.0
    }

    private func getServiceProperties(_ service: io_object_t) -> [String: Any]? {
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let properties = props?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        return properties
    }
}
