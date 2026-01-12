import Foundation
import Darwin

struct MemoryUsage {
    let used: Double
    let total: Double
    let percentage: Double
    let swapUsed: Double
    let swapTotal: Double
    let swapPercentage: Double
}

final class MemoryMetrics {
    private let pageSize: Double

    init() {
        self.pageSize = Double(vm_kernel_page_size)
    }

    func getUsage() -> MemoryUsage {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryUsage(used: 0, total: 0, percentage: 0, swapUsed: 0, swapTotal: 0, swapPercentage: 0)
        }

        // Get total physical memory
        var totalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)

        let totalGB = Double(totalMemory) / (1024 * 1024 * 1024)

        // Calculate used memory (App Memory + Wired + Compressed)
        // Using internal_page_count (anonymous/app pages) instead of active_count
        // to match Activity Monitor's "Memory Used" calculation
        let appMemoryPages = Double(stats.internal_page_count)
        let wiredPages = Double(stats.wire_count)
        let compressedPages = Double(stats.compressor_page_count)

        let usedBytes = (appMemoryPages + wiredPages + compressedPages) * pageSize
        let usedGB = usedBytes / (1024 * 1024 * 1024)

        let percentage = (usedGB / totalGB) * 100.0

        // Get swap usage
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0)

        let swapTotalGB = Double(swapUsage.xsu_total) / (1024 * 1024 * 1024)
        let swapUsedGB = Double(swapUsage.xsu_used) / (1024 * 1024 * 1024)
        let swapPercentage = swapTotalGB > 0 ? (swapUsedGB / swapTotalGB) * 100.0 : 0

        return MemoryUsage(
            used: usedGB,
            total: totalGB,
            percentage: percentage,
            swapUsed: swapUsedGB,
            swapTotal: swapTotalGB,
            swapPercentage: swapPercentage
        )
    }
}
