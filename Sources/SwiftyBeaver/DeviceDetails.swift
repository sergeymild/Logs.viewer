//
//  DeviceDetails.swift
//

import Foundation

// platform-dependent import frameworks to get device details
// valid values for os(): OSX, iOS, watchOS, tvOS, Linux
// in Swift 3 the following were added: FreeBSD, Windows, Android
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
    var DEVICE_MODEL: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        }
    }
#else
    let DEVICE_MODEL = ""
#endif

#if os(iOS) || os(tvOS)
    var DEVICE_NAME = UIDevice.current.name
#else
    // under watchOS UIDevice is not existing, http://apple.co/26ch5J1
    let DEVICE_NAME = ""
#endif

class DeviceDetails {
    // returns dict with device details. Amount depends on platform
    func deviceDetails() -> [String: String] {
        var details = [String: String]()

        details["os"] = OS
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        // becomes for example 10.11.2 for El Capitan
        var osVersionStr = String(osVersion.majorVersion)
        osVersionStr += "." + String(osVersion.minorVersion)
        osVersionStr += "." + String(osVersion.patchVersion)
        details["osVersion"] = osVersionStr
        details["hostName"] = ProcessInfo.processInfo.hostName
        details["deviceName"] = ""
        details["deviceModel"] = ""

        if DEVICE_NAME != "" {
            details["deviceName"] = DEVICE_NAME
        }
        if DEVICE_MODEL != "" {
            details["deviceModel"] = DEVICE_MODEL
        }
        return details
    }
}
