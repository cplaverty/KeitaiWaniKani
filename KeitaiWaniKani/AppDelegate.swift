//
//  AppDelegate.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Application lifecycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Logging
        #if DEBUG
            defaultDebugLevel = DDLogLevel.Verbose
        #else
            defaultDebugLevel = DDLogLevel.Info
        #endif
        
        DDLog.addLogger(DDASLLogger.sharedInstance())
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 24 * 60 * 60 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        
        DDLog.addLogger(fileLogger)
        
        DDLogInfo("Starting new instance (logging level \(defaultDebugLevel))")

        // Check if we've been launched by Snapshot
        if NSUserDefaults.standardUserDefaults().boolForKey("FASTLANE_SNAPSHOT") {
            DDLogInfo("Detected snapshot run: setting login cookie and disabling notification prompts")
            if let loginCookieValue = NSUserDefaults.standardUserDefaults().stringForKey("LOGIN_COOKIE") {
            let loginCookie = NSHTTPCookie(properties: [
                NSHTTPCookieDomain: "www.wanikani.com",
                NSHTTPCookieName: "remember_user_token",
                NSHTTPCookiePath: "/",
                NSHTTPCookieSecure: "TRUE",
                NSHTTPCookieValue: loginCookieValue
                ])!
                
                DDLogDebug("Setting login cookie value \(loginCookieValue)")
                NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(loginCookie)
                ApplicationSettings.apiKeyVerified = false
            }
        
            UserNotificationCondition.enabled = false
        }
        
        UINavigationBar.appearance().tintColor = ApplicationSettings.globalTintColor()
        UINavigationBar.appearance().barTintColor = ApplicationSettings.globalBarTintColor()
        UIToolbar.appearance().tintColor = ApplicationSettings.globalTintColor()
        UIToolbar.appearance().barTintColor = ApplicationSettings.globalBarTintColor()
        
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ApplicationSettings.purgeDatabase {
            databaseManager.recreateDatabase()
        }
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        DDLogInfo("Low memory warning: clearing statement cache")
        databaseQueue.inDatabase { $0.clearCachedStatements() }
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        DDLogInfo("Opening due to url \(url)")
        return true
    }
    
    // MARK: - Background fetch
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        DDLogDebug("In background fetch handler")
        
        // We must have an API key set, or there's no data to fetch
        guard let apiKey = ApplicationSettings.apiKey else {
            DDLogDebug("Background fetch result = .NoData (No API key set)")
            completionHandler(.NoData)
            return
        }
        
        let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
        let operation = GetDashboardDataOperation(resolver: resolver, databaseQueue: databaseQueue, forcedFetch: false, isInteractive: false)
        DDLogInfo("Background fetch study queue for API key \(apiKey)...")
        
        let completionHandlerOperationObserver = BlockObserver { operation, errors in
            guard let operation = operation as? GetDashboardDataOperation else { return }
            
            DDLogDebug("Background run of \(operation.dynamicType) finished with errors \(errors)")
            // Check if any of these errors are non-fatal
            let fatalErrors = errors.filterNonFatalErrors()
            
            if !fatalErrors.isEmpty {
                DDLogDebug("Background fetch result = .Failed")
                completionHandler(.Failed)
            } else if operation.fetchRequired {
                DDLogDebug("Background fetch result = .NewData")
                completionHandler(.NewData)
            } else {
                DDLogDebug("Background fetch result = .NoData")
                completionHandler(.NoData)
            }
        }
        
        operation.addObserver(completionHandlerOperationObserver)
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: - WKProcessPool
    
    lazy var webKitProcessPool = WKProcessPool()
    
    // MARK: - Operation queue
    
    lazy var operationQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.name = "AlliCrab worker queue"
        return oq
        }()
    
    // MARK: - SQLite Database
    
    lazy var databaseManager = DatabaseManager()
    
    var databaseQueue: FMDatabaseQueue { return databaseManager.databaseQueue }
    
}
