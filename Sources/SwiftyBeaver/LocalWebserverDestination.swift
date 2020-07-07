//
//  LocalWebserverDestination.swift
//

import Foundation
import Swifter

private enum LocalWebserverError: Error {
    case serialization
}

private var connected: [Int: WebSocketSession] = [:]

public class LocalWebserverDestination: BaseDestination {
    
    static var logs: [[String: Any]] = []
    private let analitycs = Analitycs()
    private let deviceDetails = DeviceDetails()
    private lazy var server = HttpServer()
    
    private lazy var localPath: String = {
        let bundle = Bundle(for: LocalWebserverDestination.self).resourceURL!
        let path = bundle.appendingPathComponent("com.sergeymild.LogsViewer.assets.bundle")
        return path.path
    }()
    
    public init(port: UInt16 = 8088) {
        super.init()
        start(port: port)
    }
    
    public override func send(
        _ level: LogsViewer.Level,
        msg: String,
        thread: String,
        file: String,
        function: String,
        line: Int,
        context: Any? = nil
    ) -> String? {

        do {
            let log = [
                "timestamp": Date().timeIntervalSince1970,
                "level": level.rawValue,
                "message": msg,
                "thread": thread,
                "fileName": file.components(separatedBy: "/").last!,
                "function": function,
                "line": line,
                "color": level.color
            ] as! [String: Any]
            
            let deviceDetailsDict = deviceDetails.deviceDetails()
            var analyticsDict = analitycs.analytics(shouldSaveOnDisk: false)

            for key in deviceDetailsDict.keys {
                analyticsDict[key] = deviceDetailsDict[key]
            }

            send(log: log, analitycs: analyticsDict)
            Self.logs.append(log)
            return nil
        } catch {
            
        }
        return nil
    }
    
    func send(log: [String: Any], analitycs: [String: Any]) {
        let dict = [
            "type": "log",
            "data": log,
            "analitycs": analitycs
        ] as! [String: Any]
        
        let data = jsonData(obj: dict)
        connected.values.forEach { $0.writeBinary([UInt8](data)) }
    }
    
    func send(logs: [[String: Any]]) {
        
        let dict = [
            "type": "logs",
            "data": logs
        ] as! [String: Any]
        
        let data = jsonData(obj: dict)
        connected.values.forEach { $0.writeBinary([UInt8](data)) }
    }
    
    open func start(port: UInt16) {
        let address = getWiFiAddress() ?? "localhost"
        print("===============================")
        print("=== WEBSOCKETS \(address):\(port) ===")
        print("===============================")
        server.listenAddressIPv4 = getWiFiAddress()
        try! server.start(port, forceIPv4: true)
        
        let ws = websocket(
            text: { [weak self] _, text in
                if text == "clearLogs" {
                    LocalWebserverDestination.logs = []
                    self?.send(logs: LocalWebserverDestination.logs)
                }
            },
            
            connected: { [weak self] session in
                connected[session.hashValue] = session
                self?.send(logs: LocalWebserverDestination.logs)
                print("=== connected", connected)
            },
            
            disconnected: { [weak self] session in
                do {
                    connected.removeValue(forKey: session.hashValue)
                } catch {}
                print("=== disconnected", connected)
            }
        )
        
        server["/"] = { [localPath] request in
            let url = URL(fileURLWithPath: "\(localPath)/index.html")
            do {
                return .ok(.data(try Data(contentsOf: url)))
            } catch { return .notFound }
        }
        
        server["/css/:name"] = { [localPath]  request in
            guard let name = request.params[":name"] else { return .notFound }
            let url = URL(fileURLWithPath: "\(localPath)/\(name)")
            do {
                return .ok(.data(try Data(contentsOf: url)))
            } catch { return .notFound }
        }
        
        server["/js/:name"] = { [localPath]  request in
            guard let name = request.params[":name"] else { return .notFound }
            let url = URL(fileURLWithPath: "\(localPath)/\(name)")
            do {
                return .ok(.data(try Data(contentsOf: url)))
            } catch { return .notFound }
        }
        
        server["/ws"] = ws
    }
    
    open func stop() {
        server.stop()
    }
    
    deinit {
        stop()
    }
}


private func jsonData(obj: [String: Any]) -> Data {
    let json = try? JSONSerialization.data(withJSONObject: obj, options: [])
    return json ?? Data()
}
