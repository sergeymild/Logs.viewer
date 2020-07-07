//
//  AppDelegate.swift
//  Logs.viewer-Example
//
//  Created by Orkhan Alikhanov on 7/2/17.
//  Copyright © 2017 BiAtoms. All rights reserved.
//

import UIKit
import LogsViewer

let logs = LogsViewer.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        logs.add(destination: LocalWebserverDestination())
        logs.add(destination: ConsoleDestination())
        
        logs.info("start app")
        
        return true
    }
}

