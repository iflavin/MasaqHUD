import Foundation
import CoreAudio

struct AudioInfo {
    let deviceName: String
    let volume: Int  // 0-100
    let isMuted: Bool
}

final class AudioMetrics {

    func getInfo() -> AudioInfo {
        var deviceID = AudioDeviceID()
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        // Get default output device
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &propertySize,
            &deviceID
        )

        guard status == noErr, deviceID != kAudioObjectUnknown else {
            return AudioInfo(deviceName: "Unknown", volume: 0, isMuted: false)
        }

        let deviceName = getDeviceName(deviceID: deviceID)
        let volume = getVolume(deviceID: deviceID)
        let isMuted = getMuteStatus(deviceID: deviceID)

        return AudioInfo(
            deviceName: deviceName,
            volume: Int(volume * 100),
            isMuted: isMuted
        )
    }

    private func getDeviceName(deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: Unmanaged<CFString>?
        var propertySize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &propertySize,
            &name
        )

        if status == noErr, let cfName = name?.takeRetainedValue() {
            return cfName as String
        }
        return "Unknown"
    }

    private func getVolume(deviceID: AudioDeviceID) -> Float {
        // Try master channel first (element 0)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Check if volume property exists on master channel
        if !AudioObjectHasProperty(deviceID, &propertyAddress) {
            // Try channel 1 (left)
            propertyAddress.mElement = 1
            if !AudioObjectHasProperty(deviceID, &propertyAddress) {
                return 0
            }
        }

        var volume: Float32 = 0
        var propertySize = UInt32(MemoryLayout<Float32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &propertySize,
            &volume
        )

        return status == noErr ? volume : 0
    }

    private func getMuteStatus(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        if !AudioObjectHasProperty(deviceID, &propertyAddress) {
            return false
        }

        var muted: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &propertySize,
            &muted
        )

        return status == noErr && muted != 0
    }
}
