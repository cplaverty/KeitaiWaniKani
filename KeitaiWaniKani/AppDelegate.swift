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
        
            UserNotificationCondition.notificationsEnabled = false
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
            databaseQueue = self.dynamicType.createDatabaseQueue()
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
    
    lazy var databaseQueue: FMDatabaseQueue = AppDelegate.createDatabaseQueue()
    
    static var secureAppGroupPersistentStoreURL: NSURL = {
        let fm = NSFileManager.defaultManager()
        let directory = fm.containerURLForSecurityApplicationGroupIdentifier("group.uk.me.laverty.KeitaiWaniKani")!
        return directory.URLByAppendingPathComponent("WaniKaniData.sqlite")
        }()
    
    func recreateDatabase() {
        ApplicationSettings.purgeDatabase = true
        databaseQueue = self.dynamicType.createDatabaseQueue()
    }
    
    private static func createDatabaseQueue() -> FMDatabaseQueue {
        DDLogInfo("Creating database queue using SQLite \(FMDatabase.sqliteLibVersion()) and FMDB \(FMDatabase.FMDBUserVersion())")
        let storeURL = secureAppGroupPersistentStoreURL
        
        if ApplicationSettings.purgeDatabase {
            DDLogInfo("Database purge requested.  Deleting database file at \(storeURL)")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            ApplicationSettings.purgeDatabase = false
        }
        
        var databaseQueue = createDatabaseQueueAtURL(storeURL)
        if databaseQueue == nil || !isValidDatabaseQueue(databaseQueue!) {
            // Our persistent store does not contain irreplaceable data. If we fail to add it, we can delete it and try again.
            DDLogWarn("Failed to create FMDatabaseQueue.  Deleting and trying again.")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            databaseQueue = self.createDatabaseQueueAtURL(storeURL)
        }
        
        if let queue = databaseQueue {
            return queue
        }
        
        ApplicationSettings.purgeDatabase = true
        fatalError("Failed to create database at \(storeURL)")
    }
    
    private static func isValidDatabaseQueue(databaseQueue: FMDatabaseQueue) -> Bool {
        return try! databaseQueue.withDatabase { $0.goodConnection() }
    }
    
    private static func createDatabaseQueueAtURL(URL: NSURL) -> FMDatabaseQueue? {
        assert(URL.fileURL, "createDatabaseQueueAtURL requires a file URL")
        let path = URL.path!
        DDLogInfo("Creating FMDatabaseQueue at \(path)")
        if let databaseQueue = FMDatabaseQueue(path: path) {
            var successful = false
            databaseQueue.inDatabase { database in
                do {
                    try WaniKaniAPI.createTablesInDatabase(database)
                    successful = true
                } catch {
                    DDLogError("Failed to create schema due to error: \(error)")
                }
            }
            
            if successful {
                do {
                    try URL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                } catch {
                    DDLogWarn("Ignoring error when trying to exclude store at \(URL) from backup: \(error)")
                }
                return databaseQueue
            }
        }
        return nil
    }
}
