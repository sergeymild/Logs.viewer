//
//  LogsViewer.swift
//

import Foundation

open class LogsViewer {

    /// version string of framework
    public static let version = "1.0.0"  // UPDATE ON RELEASE!
    /// build number of framework
    public static let build = 1000 // version 1.6.2 -> 1620, UPDATE ON RELEASE!

    open class Level {
        public let rawValue: String
        public let color: String
        public init(rawValue: String, color: String) {
            self.rawValue = rawValue
            self.color = color
        }
        
        public static let all = Level(rawValue: "all", color: "#4dd0e1")
        public static let verbose = Level(rawValue: "verbose", color: "#4dd0e1")
        public static let debug = Level(rawValue: "debug", color: "#4caf50")
        public static let info = Level(rawValue: "info", color: "#2196f3")
        public static let warning = Level(rawValue: "warning", color: "#ffa726")
        public static let error = Level(rawValue: "error", color: "#f44336")
        public static let `deinit` = Level(rawValue: "deinit", color: "#607d8b")
        public static let http = Level(rawValue: "http", color: "#9e9e9e")
    }

    // a set of active destinations
    private static var destinations = Set<BaseDestination>()

    // MARK: Destination Handling

    /// returns boolean about success
    @discardableResult
    open class func add(destination: BaseDestination) -> Bool {
        if destinations.contains(destination) { return false }
        destinations.insert(destination)
        return true
    }

    /// returns boolean about success
    @discardableResult
    open class func remove(destination: BaseDestination) -> Bool {
        if !destinations.contains(destination) { return false }
        destinations.remove(destination)
        return true
    }

    /// if you need to start fresh
    open class func removeAllDestinations() {
        destinations.removeAll()
    }

    /// returns the amount of destinations
    open class func countDestinations() -> Int {
        return destinations.count
    }

    // MARK: Levels

    /// log something generally unimportant (lowest priority)
    open class func verbose(
        _ message: Any? = nil,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .verbose,
            message: message,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }

    /// log something which help during debugging (low priority)
    open class func debug(
        _ message: Any? = nil,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .debug,
            message: message,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }

    /// log something which you are really interested but which is not an issue or error (normal priority)
    open class func info(
        _ message: Any? = nil,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .info,
            message: message,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }

    /// log something which may cause big trouble soon (high priority)
    open class func warning(
        _ message: Any? = nil,
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .warning,
            message: message,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }

    /// log something which will keep you awake at night (highest priority)
    open class func error(
        _ message: Any? = nil,
        _ file: String = #file,
        _ function: String = #function,
        _ line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .error,
            message: message,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }
    
    open class func `deinit`(
        _ file: String = #file,
        _ function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        custom(
            level: .deinit,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }
    
    public class func http(
        request: URLRequest?,
        response: URLResponse?,
        responseData: Data? = nil
    ) {
        guard let request = request else { return }
        guard let response = response else { return }
        let headers = request.allHTTPHeaderFields ?? [:]
        var requestString = ""
        if request.httpMethod == "POST" {
            let httpBody = request.httpBody ?? Data()
            requestString = String(data: httpBody, encoding: .utf8) ?? "empty"
        }
        let httpResponse = response as! HTTPURLResponse
        let responseHeaders = httpResponse.allHeaderFields
        var bodyString = ""
        var bodyLength = ""
        if let data = responseData {
            let bcf = ByteCountFormatter()
            bcf.countStyle = .file
            bodyString = String(data: (data ?? Data()), encoding: .utf8) ?? "empty"
            bodyLength = bcf.string(fromByteCount: Int64(data.count))
        }
        let message: [String: Any] = [
            "method": request.httpMethod ?? "UNKNOWN",
            "url": request.url?.absoluteString ?? "unknown",
            "requestHeaders": headers,
            "requestBody": requestString,
            "statusCode": httpResponse.statusCode,
            "responseHeaders": responseHeaders,
            "responseBody": bodyString,
            "bodyLength": bodyLength
        ]
        guard let string = jsonStringFromDict(message) else {
            return log("Error create http log")
        }
        
        custom(
            level: .http,
            message: string
        )
    }

    /// custom logging to manually adjust values, should just be used by other frameworks
    public class func custom(
        level: LogsViewer.Level,
        message: Any? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        dispatchSend(
            level: level,
            message: message ?? "",
            thread: threadName,
            file: file,
            function: function,
            line: line,
            context: context
        )
    }

    /// internal helper which dispatches send to dedicated queue if minLevel is ok
    class func dispatchSend(
        level: LogsViewer.Level,
        message: Any,
        thread: String,
        file: String,
        function: String,
        line: Int,
        context: Any?
    ) {
        var resolvedMessage: String?
        for dest in destinations {

            guard let queue = dest.queue else { continue }

            resolvedMessage = resolvedMessage == nil && dest.hasMessageFilters() ? "\(message)" : resolvedMessage
            if dest.shouldLevelBeLogged(level, path: file, function: function, message: resolvedMessage) {
                // try to convert msg object to String and put it on queue
                let msgStr = resolvedMessage == nil ? "\(message)" : resolvedMessage!
                let f = stripParams(function: function)

                if dest.asynchronously {
                    queue.async {
                        _ = dest.send(
                            level,
                            msg: msgStr,
                            thread: thread,
                            file: file,
                            function: f,
                            line: line,
                            context: context
                        )
                    }
                } else {
                    queue.sync {
                        _ = dest.send(
                            level,
                            msg: msgStr,
                            thread: thread,
                            file: file,
                            function: f,
                            line: line,
                            context: context
                        )
                    }
                }
            }
        }
    }

    /// removes the parameters from a function because it looks weird with a single param
    class func stripParams(function: String) -> String {
        var f = function
        if let indexOfBrace = f.firstIndex(of: "(") {
            f = String(f[..<indexOfBrace])
        }
        return f
    }
}
