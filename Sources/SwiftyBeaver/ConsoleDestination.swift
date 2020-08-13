//
//  ConsoleDestination.swift
//

import Foundation

public class ConsoleDestination: BaseDestination {

    /// use NSLog instead of print, default is false
    public var useNSLog = false


    override public var defaultHashValue: Int { return 1 }

    // print to Xcode Console. uses full base class functionality
    override public func send(
        _ level: LogsViewer.Level,
        msg: String,
        thread: String,
        file: String,
        function: String,
        line: Int,
        context: Any? = nil
    ) -> String? {
        if level == LogsViewer.Level.http { return nil }
        let formattedString = super.send(
            level,
            msg: msg,
            thread: thread,
            file: file,
            function: function,
            line: line,
            context: context
        )

        if let str = formattedString {
            print(str)
        }
        return formattedString
    }
}
