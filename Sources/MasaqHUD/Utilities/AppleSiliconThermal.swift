import Foundation
import IOKit

// MARK: - IOHIDEventSystem Private API Declarations

// IOHIDEventSystem types (private but stable API used by system monitoring tools)
private typealias IOHIDEventSystemClientRef = OpaquePointer
private typealias IOHIDServiceClientRef = OpaquePointer
private typealias IOHIDEventRef = OpaquePointer

// IOHIDEventSystem functions
@_silgen_name("IOHIDEventSystemClientCreate")
private func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> IOHIDEventSystemClientRef?

@_silgen_name("IOHIDEventSystemClientSetMatching")
private func IOHIDEventSystemClientSetMatching(_ client: IOHIDEventSystemClientRef, _ matching: CFDictionary?)

@_silgen_name("IOHIDEventSystemClientCopyServices")
private func IOHIDEventSystemClientCopyServices(_ client: IOHIDEventSystemClientRef) -> CFArray?

@_silgen_name("IOHIDServiceClientCopyProperty")
private func IOHIDServiceClientCopyProperty(_ service: IOHIDServiceClientRef, _ key: CFString) -> CFTypeRef?

@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(_ service: IOHIDServiceClientRef, _ type: Int64, _ matching: CFDictionary?, _ options: Int64) -> IOHIDEventRef?

@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: IOHIDEventRef, _ field: Int32) -> Double

// Release function for IOHIDEvent (needed since IOHIDEventRef is OpaquePointer)
@_silgen_name("CFRelease")
private func IOHIDEventRelease(_ event: IOHIDEventRef)

// Event type for temperature
private let kIOHIDEventTypeTemperature: Int64 = 15

// Field for temperature value (IOHIDEventField)
// The field format is 0x00TT00FF where TT is the event type (0x0F for temperature)
// and FF is the field index (0x00 for the base/level value)
private let kIOHIDEventFieldTemperatureLevel: Int32 = 0x000F0000

/// Thermal sensor reader for Apple Silicon Macs using IOHIDEventSystem
final class AppleSiliconThermal {

    struct ThermalReading {
        let name: String
        let temperature: Double
    }

    private var client: IOHIDEventSystemClientRef?

    init() {
        setupClient()
    }

    private func setupClient() {
        client = IOHIDEventSystemClientCreate(kCFAllocatorDefault)

        guard let client = client else {
            return
        }

        // Match for thermal sensors - PrimaryUsagePage 0xFF00 (vendor-defined), PrimaryUsage 5 (temperature)
        let matching: [String: Any] = [
            "PrimaryUsagePage": 0xFF00,
            "PrimaryUsage": 5
        ]

        IOHIDEventSystemClientSetMatching(client, matching as CFDictionary)
    }

    /// Get all available thermal sensor readings
    func getAllTemperatures() -> [ThermalReading] {
        guard let client = client else {
            return []
        }

        guard let services = IOHIDEventSystemClientCopyServices(client) else {
            return []
        }

        var readings: [ThermalReading] = []
        let count = CFArrayGetCount(services)

        for i in 0..<count {
            guard let servicePtr = CFArrayGetValueAtIndex(services, i) else {
                continue
            }
            let serviceRef = unsafeBitCast(servicePtr, to: IOHIDServiceClientRef.self)

            // Get the sensor name
            var name = "sensor\(i)"
            if let nameRef = IOHIDServiceClientCopyProperty(serviceRef, "Product" as CFString),
               let n = nameRef as? String {
                name = n
            }

            // Get the temperature event
            guard let event = IOHIDServiceClientCopyEvent(serviceRef, kIOHIDEventTypeTemperature, nil, 0) else {
                continue
            }

            let temperature = IOHIDEventGetFloatValue(event, kIOHIDEventFieldTemperatureLevel)

            // Release the event - it's a "Copy" function so we own it
            IOHIDEventRelease(event)

            // Filter out invalid readings (some sensors return garbage values)
            if temperature > 0 && temperature < 120 {
                readings.append(ThermalReading(name: name, temperature: temperature))
            }
        }

        return readings
    }

    /// Get CPU temperature by finding the most relevant CPU thermal sensor
    func getCPUTemperature() -> Double? {
        let readings = getAllTemperatures()

        // Priority order for CPU temperature sensors on Apple Silicon
        // SOC MTR Temp is usually the main die temperature
        // pACC = performance cores, eACC = efficiency cores
        let cpuPatterns = [
            "SOC MTR Temp",
            "PMU tdie",
            "PMU TP",
            "CPU",
            "Die",
            "pACC",
            "eACC"
        ]

        // Try to find the best match in priority order
        for pattern in cpuPatterns {
            if let reading = readings.first(where: { $0.name.localizedCaseInsensitiveContains(pattern) }) {
                return reading.temperature
            }
        }

        // If no specific CPU sensor found, return the hottest reading as a fallback
        // (usually represents the CPU die on Apple Silicon)
        return readings.max(by: { $0.temperature < $1.temperature })?.temperature
    }

    /// Get GPU temperature by finding GPU-specific thermal sensor
    func getGPUTemperature() -> Double? {
        let readings = getAllTemperatures()

        // Look for GPU-specific sensors
        let gpuPatterns = [
            "GPU MTR Temp",
            "GPU",
            "gpu"
        ]

        for pattern in gpuPatterns {
            if let reading = readings.first(where: { $0.name.localizedCaseInsensitiveContains(pattern) }) {
                return reading.temperature
            }
        }

        // On Apple Silicon, GPU is on the same die - no dedicated sensor may exist
        return nil
    }

    /// Get temperatures suitable for the existing TemperatureInfo structure
    func getTemperatures() -> TemperatureInfo {
        let cpuTemp = getCPUTemperature() ?? 0
        let gpuTemp = getGPUTemperature() ?? 0

        return TemperatureInfo(cpuTemp: cpuTemp, gpuTemp: gpuTemp)
    }
}
