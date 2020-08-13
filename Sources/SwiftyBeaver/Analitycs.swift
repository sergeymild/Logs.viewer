//
//  Analitycs.swift
//

import Foundation

/// returns the current thread name
var threadName: String {
    #if os(Linux)
        // on 9/30/2016 not yet implemented in server-side Swift:
        // > import Foundation
        // > Thread.isMainThread
        return ""
    #else
        if Thread.isMainThread {
            return ""
        } else {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8) ?? Thread.current.description
        }
    #endif
}

class Analitycs {
    var uuid = ""
    var analyticsUserName = "" // user email, ID, name, etc.
    var analyticsUUID: String { return uuid }
    var fileURL: URL?
    var saver = FileSaver()
    
    func setFileURL(baseURL: URL?, fileName: String) {
        guard let baseURL = baseURL else { return }
        #if os(Linux)
            fileURL = URL(fileURLWithPath: "/var/cache/\(analyticsFileName)")
        #endif
        
        #if !os(Linux)
        fileURL = baseURL.appendingPathComponent(
            fileName,
            isDirectory: false
        )
        #endif
    }
    
    /// returns (updated) analytics dict, optionally loaded from file.
    @discardableResult
    func analytics(shouldSaveOnDisk: Bool = true, update: Bool = false) -> [String: Any] {

        var dict = [String: Any]()
        let now = NSDate().timeIntervalSince1970

        uuid =  UUID().uuidString
        dict["uuid"] = uuid
        dict["firstStart"] = now
        dict["lastStart"] = now
        dict["starts"] = 1
        dict["userName"] = analyticsUserName
        dict["firstAppVersion"] = appVersion()
        dict["appVersion"] = appVersion()
        dict["firstAppBuild"] = appBuild()
        dict["appBuild"] = appBuild()
        dict["identifier"] = Bundle.main.bundleIdentifier
        dict["deviceId"] = UIDevice.current.identifierForVendor!.uuidString

        if let url = fileURL,
            let loadedDict = dictFromFile(url) {
            if let val = loadedDict["firstStart"] as? Double {
                dict["firstStart"] = val
            }
            if let val = loadedDict["lastStart"] as? Double {
                if update { dict["lastStart"] = now }
                else { dict["lastStart"] = val }
            }
            if let val = loadedDict["starts"] as? Int {
                if update {
                    dict["starts"] = val + 1
                } else {
                    dict["starts"] = val
                }
            }
            if let val = loadedDict["uuid"] as? String {
                dict["uuid"] = val
                uuid = val
            }
            if let val = loadedDict["userName"] as? String {
                if update && !analyticsUserName.isEmpty {
                    dict["userName"] = analyticsUserName
                } else {
                    if !val.isEmpty {
                        dict["userName"] = val
                    }
                }
            }
            if let val = loadedDict["firstAppVersion"] as? String {
                dict["firstAppVersion"] = val
            }
            if let val = loadedDict["firstAppBuild"] as? Int {
                dict["firstAppBuild"] = val
            }
        }
        if shouldSaveOnDisk, let url = fileURL {
            saver.saveDictToFile(dict, url: url)
        }
        return dict
    }



    /// Returns the current app version string (like 1.2.5) or empty string on error
    func appVersion() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                return version
        }
        return ""
    }

    /// Returns the current app build as integer (like 563, always incrementing) or 0 on error
    func appBuild() -> Int {
        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return Int(version) ?? 0
        }
        return 0
    }

    /// returns optional dict from a json encoded file
    func dictFromFile(_ url: URL) -> [String: Any]? {
        do {
            let fileContent = try String(contentsOfFile: url.path, encoding: .utf8)
            if let data = fileContent.data(using: .utf8) {
                return try JSONSerialization.jsonObject(
                    with: data,
                    options: .mutableContainers) as? [String: Any]
            }
        } catch {
            log("LogsViewer Platform Destination could not read file \(url)")
        }
        return nil
    }

}
