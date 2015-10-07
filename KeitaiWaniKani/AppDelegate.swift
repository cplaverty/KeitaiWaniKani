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

    // MARK: Application lifecycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        #if DEBUG
            defaultDebugLevel = DDLogLevel.Verbose
        #else
            // TODO: Change to Info once stable
            defaultDebugLevel = DDLogLevel.Debug
        #endif
        
        DDLog.addLogger(DDASLLogger.sharedInstance())
        DDLog.addLogger(DDTTYLogger.sharedInstance())
        
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 24 * 60 * 60 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        
        DDLog.addLogger(fileLogger)
        
        DDLogInfo("Starting new instance (logging level \(defaultDebugLevel))")
        
        let barTintColor = UIColor(hue: 180 / 360, saturation: 0.05, brightness: 0.9, alpha: 1)
        UINavigationBar.appearance().tintColor = ApplicationSettings.globalTintColor
        UINavigationBar.appearance().barTintColor = barTintColor
        UIToolbar.appearance().tintColor = ApplicationSettings.globalTintColor
        UIToolbar.appearance().barTintColor = barTintColor
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ApplicationSettings.purgeDatabase {
            databaseQueue = self.dynamicType.createDatabaseQueue()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: Background fetch
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        DDLogInfo("In background fetch handler")
        
        // We must have an API key set, or there's no data to fetch
        guard let apiKey = ApplicationSettings.apiKey else {
            DDLogInfo("Background fetch result = .NoData (No API key set)")
            completionHandler(.NoData)
            return
        }
        
        let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
        let operation = GetDashboardDataOperation(resolver: resolver, databaseQueue: databaseQueue, forcedFetch: false)
        DDLogInfo("Background fetch study queue for API key \(apiKey)...")
        
        let completionHandlerOperationObserver = BlockObserver { operation, errors in
            guard let operation = operation as? GetDashboardDataOperation else { return }
            
            DDLogInfo("Background run of \(operation.dynamicType) finished with errors \(errors)")
            // Check if any of these errors are non-fatal
            let fatalErrors = errors.filterNonFatalErrors()
            
            if !fatalErrors.isEmpty {
                DDLogInfo("Background fetch result = .Failed")
                completionHandler(.Failed)
            } else if operation.fetchRequired {
                DDLogInfo("Background fetch result = .NewData")
                completionHandler(.NewData)
            } else {
                DDLogInfo("Background fetch result = .NoData")
                completionHandler(.NoData)
            }
        }
        
        operation.addObserver(completionHandlerOperationObserver)
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: WKProcessPool
    
    lazy var webKitProcessPool = WKProcessPool()
    
    // MARK: Operation queue

    lazy var operationQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.name = "KeitaiWaniKani worker queue"
        return oq
        }()
    
    // MARK: SQLite Database
    
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
