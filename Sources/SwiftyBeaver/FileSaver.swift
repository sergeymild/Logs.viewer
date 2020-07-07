//
//  FileSaver.swift
//

import Foundation

/// turns dict into JSON-encoded string
func jsonStringFromDict(_ dict: [String: Any]) -> String? {
    var jsonString: String?

    // try to create JSON string
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        jsonString = String(data: jsonData, encoding: .utf8)
    } catch {
        print("LogsViewer could not create JSON from dict.")
    }
    return jsonString
}

class FileSaver {
    let fileManager = FileManager.default
    // MARK: File Handling

    /// appends a string as line to a file.
    /// returns boolean about success
    @discardableResult
    func saveToFile(_ str: String, url: URL, overwrite: Bool = false) -> Bool {
        do {
            if fileManager.fileExists(atPath: url.path) == false || overwrite {
                // create file if not existing
                let line = str + "\n"
                try line.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            } else {
                // append to end of file
                let fileHandle = try FileHandle(forWritingTo: url)
                _ = fileHandle.seekToEndOfFile()
                let line = str + "\n"
                if let data = line.data(using: String.Encoding.utf8) {
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
            return true
        } catch {
            log("Error! Could not write to file \(url).")
            return false
        }
    }

    func fileExists(url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func rename(from: URL, to: URL) -> Bool {
        do {
            try fileManager.moveItem(at: from, to: to)
            return true
        } catch {
            log("LogsViewer Platform Destination could not rename json file.")
            return false
        }
    }

    /// returns optional array of log dicts from a file which has 1 json string per line
    func logsFromFile(_ url: URL) -> [[String: Any]]? {
        var lines = 0
        do {
            // try to read file, decode every JSON line and put dict from each line in array
            let fileContent = try String(contentsOfFile: url.path, encoding: .utf8)
            let linesArray = fileContent.components(separatedBy: "\n")
            var dicts = [[String: Any]()] // array of dictionaries
            for lineJSON in linesArray {
                lines += 1
                if lineJSON.first == "{" && lineJSON.last == "}" {
                    // try to parse json string into dict
                    if let data = lineJSON.data(using: .utf8) {
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: data,
                                options: .mutableContainers) as? [String: Any] {
                                if !dict.isEmpty {
                                    dicts.append(dict)
                                }
                            }
                        } catch {
                            var msg = "Error! Could not parse "
                            msg += "line \(lines) in file \(url)."
                            log(msg)
                        }
                    }
                }
            }
            dicts.removeFirst()
            return dicts
        } catch {
            log("Error! Could not read file \(url).")
        }
        return nil
    }
    
    /// Delete file to get started again
    @discardableResult
    func deleteFile(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            log("Warning! Could not delete file \(url).")
        }
        return false
    }

    /// turns dict into JSON and saves it to file
    @discardableResult
    func saveDictToFile(_ dict: [String: Any], url: URL) -> Bool {
        if let str = jsonStringFromDict(dict) {
            log("saving '\(str)' to \(url)")
            return saveToFile(str, url: url, overwrite: true)
        }
        return false
    }
}
