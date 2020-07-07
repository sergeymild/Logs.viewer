//
//  Log.swift
//

import Foundation


private var showLog = false

func log(_ str: String) {
    if showLog {
        print("SBPlatform: \(str)")
    }
}
