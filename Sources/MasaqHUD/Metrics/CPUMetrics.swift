import Foundation
import Darwin

struct PerCoreUsage {
    let core: Int
    let usage: Double
}

struct LoadAverages {
    let load1: Double
    let load5: Double
    let load15: Double
}

final class CPUMetrics {
    private var previousTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?
    private var previousPerCoreTicks: [[UInt64]] = []
    private let coreCount: Int

    init() {
        var count: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &cpuInfo, &numCpuInfo)
        if result == KERN_SUCCESS {
            coreCount = Int(count)
            if let info = cpuInfo {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride))
            }
        } else {
            coreCount = ProcessInfo.processInfo.processorCount
        }
    }

    func getUsage() -> Double {
        var cpuLoadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0.0
        }

        let user = UInt64(cpuLoadInfo.cpu_ticks.0)
        let system = UInt64(cpuLoadInfo.cpu_ticks.1)
        let idle = UInt64(cpuLoadInfo.cpu_ticks.2)
        let nice = UInt64(cpuLoadInfo.cpu_ticks.3)

        let currentTicks = (user: user, system: system, idle: idle, nice: nice)

        defer { previousTicks = currentTicks }

        guard let previous = previousTicks else {
            return 0.0
        }

        let userDiff = user - previous.user
        let systemDiff = system - previous.system
        let idleDiff = idle - previous.idle
        let niceDiff = nice - previous.nice

        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff

        guard totalTicks > 0 else {
            return 0.0
        }

        let usedTicks = userDiff + systemDiff + niceDiff
        let rawUsage = (Double(usedTicks) / Double(totalTicks)) * 100.0

        return rawUsage
    }

    func getCoreCount() -> Int {
        return coreCount
    }

    func getPerCoreUsage() -> [PerCoreUsage] {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo)

        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return []
        }

        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride))
        }

        var currentTicks: [[UInt64]] = []
        var usages: [PerCoreUsage] = []

        for i in 0..<Int(numCPUs) {
            let offset = Int32(i) * CPU_STATE_MAX
            let user = UInt64(info[Int(offset + CPU_STATE_USER)])
            let system = UInt64(info[Int(offset + CPU_STATE_SYSTEM)])
            let idle = UInt64(info[Int(offset + CPU_STATE_IDLE)])
            let nice = UInt64(info[Int(offset + CPU_STATE_NICE)])

            currentTicks.append([user, system, idle, nice])

            var usage: Double = 0.0
            if previousPerCoreTicks.count > i {
                let prev = previousPerCoreTicks[i]
                let userDiff = user - prev[0]
                let systemDiff = system - prev[1]
                let idleDiff = idle - prev[2]
                let niceDiff = nice - prev[3]

                let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
                let usedTicks = userDiff + systemDiff + niceDiff

                usage = totalTicks > 0 ? (Double(usedTicks) / Double(totalTicks)) * 100.0 : 0.0
            }
            usages.append(PerCoreUsage(core: i, usage: usage))
        }

        previousPerCoreTicks = currentTicks
        return usages
    }

    func getLoadAverages() -> LoadAverages {
        var loadavg: [Double] = [0, 0, 0]
        getloadavg(&loadavg, 3)
        return LoadAverages(load1: loadavg[0], load5: loadavg[1], load15: loadavg[2])
    }

    func getFrequencyMHz() -> Int {
        var freq: Int64 = 0
        var size = MemoryLayout<Int64>.size
        // Try max frequency first (works on both Intel and Apple Silicon)
        if sysctlbyname("hw.cpufrequency_max", &freq, &size, nil, 0) == 0 && freq > 0 {
            return Int(freq / 1_000_000)
        }
        // Fallback to nominal frequency
        if sysctlbyname("hw.cpufrequency", &freq, &size, nil, 0) == 0 && freq > 0 {
            return Int(freq / 1_000_000)
        }
        return 0
    }
}
