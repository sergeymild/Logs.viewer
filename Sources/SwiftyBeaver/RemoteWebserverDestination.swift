//
//  RemoteWebserverDestination.swift
//

import Foundation
import SocketIO
import os

private let manager = SocketManager(
    socketURL: URL(string: "wss://applog.test.connect.lol")!,
    config: [.log(true), .forceWebsockets(true), .secure(true), .reconnects(true), .path("/socket.io/")]
)

private let socket = manager.defaultSocket

public class RemoteWebserverDestination: BaseDestination {
    static var logs: [[String: Any]] = []
    private let analitycs = Analitycs()
    private let deviceDetails = DeviceDetails()
    private var shouldStartSendLogs = false
    
    private lazy var analitycsData: [String: Any] = {
        return analitycs.analytics()
    }()
    
    private lazy var deviceDetailsData: [String: Any] = {
        return deviceDetails.deviceDetails()
    }()
    
    private lazy var localPath: String = {
        let bundle = Bundle(for: RemoteWebserverDestination.self).resourceURL!
        let path = bundle.appendingPathComponent("com.sergeymild.LogsViewer.assets.bundle")
        return path.path
    }()
    
    public override init() {
        super.init()
        socket.connect()
        
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("socket connected")
            self?.sendInit()
        }
        
        socket.on(clientEvent: .error) { data, ack in
            print("socket error", data)
        }
        
        socket.on("mobile") { [weak self] data, ack in
            if data.isEmpty { return }
            let dict = dictionaryFromAny(data: data[0])
            if dict["type"] as? String == "client-init" {
                self?.shouldStartSendLogs = true
                self?.sendInitialLogs()
            }
        }
    }
    
    private func sendInit() {
        let message = jsonString(obj: [
            "type": "mobile-init",
            "app_id": analitycsData["identifier"]!,
            "device_id": analitycsData["deviceId"]!
        ])
        socket.emit("mobile", message)
    }
    
    private func sendInitialLogs() {
        let dict = [
            "type": "log-data",
            "payload": Self.logs
        ] as! [String: Any]
        let message = jsonString(obj: dict)
        socket.emit("mobile", message)
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
        //connected.values.forEach { $0.writeBinary([UInt8](data)) }
    }
    
    func send(logs: [[String: Any]]) {
        
        let dict = [
            "type": "logs",
            "data": logs
        ] as! [String: Any]
        
        let data = jsonData(obj: dict)
        //connected.values.forEach { $0.writeBinary([UInt8](data)) }
    }
    
    deinit {
        socket.disconnect()
    }
}
