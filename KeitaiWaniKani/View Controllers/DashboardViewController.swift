//
//  DashboardViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

class DashboardViewController: UITableViewController, WebViewControllerDelegate, WKWebViewControllerDelegate {
    
    private struct SegueIdentifiers {
        static let radicalsProgress = "Show Radicals Progress"
        static let kanjiProgress = "Show Kanji Progress"
        static let levelDataChart = "Show Level Data Chart"
    }
    
    private enum TableViewSections: Int {
        case CurrentlyAvailable = 0, NextReview = 1, LevelProgress = 2, SRSDistribution = 3, Links = 4
    }
    
    // MARK: - Properties
    
    var progressDescriptionLabel: UILabel!
    var progressAdditionalDescriptionLabel: UILabel!
    var progressView: UIProgressView!
    
    private var updateUITimer: NSTimer? {
        willSet {
            updateUITimer?.invalidate()
        }
    }
    private var updateStudyQueueTimer: NSTimer? {
        willSet {
            updateStudyQueueTimer?.invalidate()
        }
    }
    
    private var userInformation: UserInformation? {
        didSet {
            if userInformation != oldValue {
                self.updateUIForUserInformation(userInformation)
            }
        }
    }
    
    private var studyQueue: StudyQueue? {
        didSet {
            if studyQueue != oldValue {
                self.updateUIForStudyQueue(studyQueue)
            }
        }
    }
    
    private var levelProgression: LevelProgression? {
        didSet {
            if levelProgression != oldValue {
                self.updateUIForLevelProgression(levelProgression)
            }
        }
    }
    
    private var srsDistribution: SRSDistribution? {
        didSet {
            if srsDistribution != oldValue {
                self.updateUIForSRSDistribution(srsDistribution)
            }
        }
    }
    
    private var levelData: LevelData? {
        didSet {
            if levelData != oldValue {
                self.updateUIForLevelData(levelData)
            }
        }
    }
    
    private var apiDataNeedsRefresh: Bool {
        return ApplicationSettings.needsRefresh() || userInformation == nil || studyQueue == nil || levelProgression == nil || srsDistribution == nil
    }
    
    private var dashboardViewControllerObservationContext = 0
    private let progressObservedKeys = ["fractionCompleted", "completedUnitCount", "totalUnitCount", "localizedDescription", "localizedAdditionalDescription"]
    private var dataRefreshOperation: GetDashboardDataOperation? {
        willSet {
            guard let formerDataRefreshOperation = dataRefreshOperation else { return }
            
            let formerProgress = formerDataRefreshOperation.progress
            for overallProgressObservedKey in progressObservedKeys {
                formerProgress.removeObserver(self, forKeyPath: overallProgressObservedKey, context: &dashboardViewControllerObservationContext)
            }
            
            if formerProgress.fractionCompleted < 1 && formerProgress.cancellable {
                DDLogDebug("Cancelling incomplete operation \(ObjectIdentifier(formerDataRefreshOperation).uintValue)")
                formerDataRefreshOperation.cancel()
            }
        }
        
        didSet {
            if let newDataRefreshOperation = dataRefreshOperation {
                refreshControl?.beginRefreshing()
                let progress = newDataRefreshOperation.progress
                for overallProgressObservedKey in progressObservedKeys {
                    progress.addObserver(self, forKeyPath: overallProgressObservedKey, options: [], context: &dashboardViewControllerObservationContext)
                }
            } else {
                refreshControl?.endRefreshing()
            }
            
            updateProgress()
        }
    }
    
    private var overallProgress: NSProgress? {
        return dataRefreshOperation?.progress
    }
    
    private var progressViewIsHidden: Bool {
        return progressView == nil || progressView?.alpha == 0
    }
    
    private let blurEffect = UIBlurEffect(style: .ExtraLight)
    
    /// Formats percentages in truncated to whole percents (as the WK dashboard does)
    private lazy var percentFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.roundingMode = .RoundDown
        formatter.roundingIncrement = 0.01
        return formatter
    }()
    
    private lazy var lastRefreshTimeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    private lazy var averageLevelDurationFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Day, .Hour]
        formatter.allowsFractionalUnits = true
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .Abbreviated
        return formatter
    }()
    
    private var databaseQueue: FMDatabaseQueue {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.databaseQueue
    }
    
    // MARK: - Outlets
    
    // MARK: Currently Available
    
    @IBOutlet weak var pendingLessonsLabel: UILabel!
    @IBOutlet weak var lessonsCell: UITableViewCell!
    @IBOutlet weak var reviewTitleLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    @IBOutlet weak var reviewTimeRemainingLabel: UILabel!
    @IBOutlet weak var reviewsCell: UITableViewCell!
    
    // MARK: Upcoming Reviews
    
    @IBOutlet weak var reviewsNextHourLabel: UILabel!
    @IBOutlet weak var reviewsNextDayLabel: UILabel!
    
    // MARK: Level Progress
    
    @IBOutlet weak var radicalPercentageCompletionLabel: UILabel!
    @IBOutlet weak var radicalTotalItemCountLabel: UILabel!
    @IBOutlet weak var radicalProgressView: UIProgressView!
    @IBOutlet weak var kanjiPercentageCompletionLabel: UILabel!
    @IBOutlet weak var kanjiTotalItemCountLabel: UILabel!
    @IBOutlet weak var kanjiProgressView: UIProgressView!
    @IBOutlet weak var averageLevelTimeCell: UITableViewCell!
    @IBOutlet weak var currentLevelTimeCell: UITableViewCell!
    @IBOutlet weak var currentLevelTimeRemainingCell: UITableViewCell!
    
    // MARK: SRS Distribution
    
    @IBOutlet weak var apprenticeCell: UITableViewCell!
    @IBOutlet weak var guruCell: UITableViewCell!
    @IBOutlet weak var masterCell: UITableViewCell!
    @IBOutlet weak var enlightenedCell: UITableViewCell!
    @IBOutlet weak var burnedCell: UITableViewCell!
    
    // MARK: - Actions
    
    @IBAction func refresh(sender: UIRefreshControl) {
        fetchStudyQueueFromNetworkInBackground(forced: true)
    }
    
    // Unwind segue when web browser is dismissed
    @IBAction func forceRefreshStudyQueue(segue: UIStoryboardSegue) {
        fetchStudyQueueFromNetworkInBackground(forced: true)
    }
    
    func showLessonsView() {
        presentReviewPageWebViewControllerForURL(WaniKaniURLs.lessonSession)
    }
    
    func showReviewsView() {
        presentReviewPageWebViewControllerForURL(WaniKaniURLs.reviewSession)
    }
    
    // MARK: - Update UI
    
    func updateUI() {
        updateUIForStudyQueue(studyQueue)
        updateUIForLevelProgression(levelProgression)
        updateUIForUserInformation(userInformation)
        updateUIForSRSDistribution(srsDistribution)
        updateUIForLevelData(levelData)
        updateProgress()
    }
    
    // MARK: Progress
    
    func updateProgress() {
        updateProgressLabels()
        updateProgressView()
    }
    
    func updateProgressLabels() {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        // Description label text
        let localizedDescription = overallProgress?.localizedDescription
        if localizedDescription?.isEmpty == false {
            progressDescriptionLabel?.text = localizedDescription
        } else {
            let formattedLastRefreshTime = ApplicationSettings.lastRefreshTime.map { $0.timeIntervalSinceNow > -60 ? "Just Now" : lastRefreshTimeFormatter.stringFromDate($0) } ?? "Never"
            progressDescriptionLabel?.text = "Updated \(formattedLastRefreshTime)"
        }
        
        // Additional description label text
        if let localizedAdditionalDescription = overallProgress?.localizedAdditionalDescription {
            // Set the text only if it is non-empty.  Otherwise, keep the existing text.
            if !localizedAdditionalDescription.isEmpty {
                progressAdditionalDescriptionLabel?.text = localizedAdditionalDescription
            }
            // Update the visibility based on whether there's text in the label or not
            progressAdditionalDescriptionLabel?.hidden = progressAdditionalDescriptionLabel?.text?.isEmpty != false
        } else {
            progressAdditionalDescriptionLabel?.text = nil
            progressAdditionalDescriptionLabel?.hidden = true
        }
    }
    
    func updateProgressView() {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        guard let progressView = progressView else { return }
        
        // Progress view visibility
        let shouldHide: Bool
        let fractionCompleted: Float
        if let overallProgress = self.overallProgress {
            shouldHide = overallProgress.finished || overallProgress.cancelled
            fractionCompleted = Float(overallProgress.fractionCompleted)
        } else {
            shouldHide = true
            fractionCompleted = 0
        }
        
        if !progressViewIsHidden && shouldHide {
            UIView.animateWithDuration(0.1) {
                progressView.setProgress(1.0, animated: false)
            }
            UIView.animateWithDuration(0.2, delay: 0.1, options: [.CurveEaseIn],
                animations: {
                    progressView.alpha = 0
                },
                completion: { _ in
                    progressView.setProgress(0.0, animated: false)
            })
        } else if progressViewIsHidden && !shouldHide {
            progressView.setProgress(0.0, animated: false)
            progressView.alpha = 1.0
            progressView.setProgress(fractionCompleted, animated: true)
        } else if !progressViewIsHidden && !shouldHide {
            progressView.setProgress(fractionCompleted, animated: true)
        }
    }
    
    // MARK: Model
    
    func updateUIForStudyQueue(studyQueue: StudyQueue?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        guard let studyQueue = self.studyQueue else {
            pendingLessonsLabel.text = "–"
            lessonsCell.accessoryType = .DisclosureIndicator
            reviewTitleLabel.text = "Reviews"
            reviewCountLabel.text = "–"
            reviewTimeRemainingLabel.text = nil
            reviewsNextHourLabel.text = "–"
            reviewsNextDayLabel.text = "–"
            reviewsCell.accessoryType = .DisclosureIndicator
            return
        }
        
        setCount(studyQueue.lessonsAvailable, forLabel: pendingLessonsLabel, availableColour: self.view.tintColor)
        pendingLessonsLabel.font = UIFont.systemFontOfSize(24, weight: studyQueue.lessonsAvailable > 0 ? UIFontWeightRegular : UIFontWeightThin)
        lessonsCell.accessoryType = studyQueue.lessonsAvailable > 0 ? .DisclosureIndicator : .None
        
        setCount(studyQueue.reviewsAvailableNextHour, forLabel: reviewsNextHourLabel)
        setCount(studyQueue.reviewsAvailableNextDay, forLabel: reviewsNextDayLabel)
        
        setTimeToNextReview(studyQueue)
    }
    
    private func setCount(count: Int, forLabel label: UILabel?, availableColour: UIColor = UIColor.blackColor(), unavailableColour: UIColor = UIColor.lightGrayColor()) {
        guard let label = label else { return }
        
        label.text = NSNumberFormatter.localizedStringFromNumber(count, numberStyle: .DecimalStyle)
        label.textColor = count > 0 ? availableColour : unavailableColour
    }
    
    func setTimeToNextReview(studyQueue: StudyQueue) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        switch studyQueue.formattedTimeToNextReview() {
        case .None, .Now:
            reviewsCell.accessoryType = .DisclosureIndicator
            reviewTitleLabel.text = "Reviews"
            setCount(studyQueue.reviewsAvailable, forLabel: reviewCountLabel, availableColour: self.view.tintColor)
            reviewCountLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
            reviewTimeRemainingLabel.text = nil
        case .FormattedString(let formattedInterval):
            reviewsCell.accessoryType = .None
            reviewTitleLabel.text = "Next Review"
            reviewCountLabel.text = studyQueue.formattedNextReviewDate()
            reviewCountLabel.textColor = UIColor.blackColor()
            reviewCountLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightThin)
            reviewTimeRemainingLabel.text = formattedInterval
        case .UnformattedInterval(let secondsUntilNextReview):
            reviewsCell.accessoryType = .None
            reviewTitleLabel.text = "Next Review"
            reviewCountLabel.text = studyQueue.formattedNextReviewDate()
            reviewCountLabel.textColor = UIColor.blackColor()
            reviewCountLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightThin)
            reviewTimeRemainingLabel.text = "\(NSNumberFormatter.localizedStringFromNumber(secondsUntilNextReview, numberStyle: .DecimalStyle))s"
        }
    }
    
    func updateUIForLevelProgression(levelProgression: LevelProgression?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        guard let levelProgression = self.levelProgression else {
            return
        }
        
        self.updateLevelProgressCellTo(levelProgression.radicalsProgress, ofTotal: levelProgression.radicalsTotal, percentageCompletionLabel: radicalPercentageCompletionLabel, progressView: radicalProgressView, totalItemCountLabel: radicalTotalItemCountLabel)
        self.updateLevelProgressCellTo(levelProgression.kanjiProgress, ofTotal: levelProgression.kanjiTotal, percentageCompletionLabel: kanjiPercentageCompletionLabel, progressView: kanjiProgressView, totalItemCountLabel: kanjiTotalItemCountLabel)
    }
    
    func updateUIForUserInformation(userInformation: UserInformation?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        self.tableView.reloadSections(NSIndexSet(index: TableViewSections.LevelProgress.rawValue), withRowAnimation: .None)
    }
    
    func updateLevelProgressCellTo(complete: Int, ofTotal total: Int, percentageCompletionLabel: UILabel?, progressView: UIProgressView?, totalItemCountLabel: UILabel?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        let fractionComplete = total == 0 ? 1.0 : Double(complete) / Double(total)
        let formattedFractionComplete = percentFormatter.stringFromNumber(fractionComplete) ?? "–%"
        
        percentageCompletionLabel?.text = formattedFractionComplete
        progressView?.setProgress(Float(fractionComplete), animated: true)
        totalItemCountLabel?.text = NSNumberFormatter.localizedStringFromNumber(total, numberStyle: .DecimalStyle)
    }
    
    func updateUIForSRSDistribution(srsDistribution: SRSDistribution?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        let pairs: [(SRSLevel, UILabel?)] = [
            (.Apprentice, apprenticeCell.detailTextLabel),
            (.Guru, guruCell.detailTextLabel),
            (.Master, masterCell.detailTextLabel),
            (.Enlightened, enlightenedCell.detailTextLabel),
            (.Burned, burnedCell.detailTextLabel),
        ]
        
        for (srsLevel, label) in pairs {
            let itemCounts = srsDistribution?.countsBySRSLevel[srsLevel] ?? SRSItemCounts.zero
            let formattedCount = NSNumberFormatter.localizedStringFromNumber(itemCounts.total, numberStyle: .DecimalStyle)
            label?.text = formattedCount
        }
        
        self.tableView.reloadSections(NSIndexSet(index: TableViewSections.SRSDistribution.rawValue), withRowAnimation: .None)
    }
    
    func updateUIForLevelData(levelData: LevelData?) {
        assert(NSThread.isMainThread(), "Must be called on the main thread")
        
        defer { self.tableView.reloadSections(NSIndexSet(index: TableViewSections.LevelProgress.rawValue), withRowAnimation: .None) }
        
        guard let
            levelData = levelData,
            averageLevelDuration = levelData.averageLevelDuration,
            projectedCurrentLevel = levelData.projectedCurrentLevel
            else {
                currentLevelTimeCell.detailTextLabel?.text = "–"
                currentLevelTimeRemainingCell.detailTextLabel?.text = "–"
                return
        }
        
        let formattedAverageLevelDuration = averageLevelDurationFormatter.stringFromTimeInterval(averageLevelDuration) ?? "\(NSNumberFormatter.localizedStringFromNumber(averageLevelDuration, numberStyle: .DecimalStyle))s"
        averageLevelTimeCell.detailTextLabel?.text = formattedAverageLevelDuration
        
        let startDate = projectedCurrentLevel.startDate
        let timeSinceLevelStart = -startDate.timeIntervalSinceNow
        let formattedTimeSinceLevelStart = averageLevelDurationFormatter.stringFromTimeInterval(timeSinceLevelStart) ?? "\(NSNumberFormatter.localizedStringFromNumber(timeSinceLevelStart, numberStyle: .DecimalStyle))s"
        
        currentLevelTimeCell.detailTextLabel?.text = formattedTimeSinceLevelStart
        
        let expectedEndDate: NSDate
        let endDateByProjection = projectedCurrentLevel.endDate
        if projectedCurrentLevel.endDateBasedOnLockedItem {
            let endDateByEstimate = startDate.dateByAddingTimeInterval(averageLevelDuration)
            expectedEndDate = endDateByEstimate.laterDate(endDateByProjection)
        } else {
            expectedEndDate = endDateByProjection
        }
        
        let timeUntilLevelCompletion = expectedEndDate.timeIntervalSinceNow
        let formattedTimeUntilLevelCompletion = timeUntilLevelCompletion <= 0 ? "–" : averageLevelDurationFormatter.stringFromTimeInterval(timeUntilLevelCompletion) ?? "\(NSNumberFormatter.localizedStringFromNumber(timeUntilLevelCompletion, numberStyle: .DecimalStyle))s"
        
        currentLevelTimeRemainingCell.textLabel?.text = projectedCurrentLevel.endDateBasedOnLockedItem ? "Level Up In (Estimated)" : "Level Up In"
        currentLevelTimeRemainingCell.detailTextLabel?.text = formattedTimeUntilLevelCompletion
    }
    
    // MARK: - Data Fetch
    
    func fetchStudyQueueFromDatabase() {
        databaseQueue.inDatabase { database in
            do {
                let userInformation = try UserInformation.coder.loadFromDatabase(database)
                let studyQueue = try StudyQueue.coder.loadFromDatabase(database)
                let levelProgression = try LevelProgression.coder.loadFromDatabase(database)
                let srsDistribution = try SRSDistribution.coder.loadFromDatabase(database)
                let levelData = try SRSDataItemCoder.levelTimeline(database)
                dispatch_async(dispatch_get_main_queue()) {
                    self.userInformation = userInformation
                    self.studyQueue = studyQueue
                    self.levelProgression = levelProgression
                    self.srsDistribution = srsDistribution
                    self.levelData = levelData
                    self.updateProgress()
                    
                    DDLogDebug("Fetch of latest StudyQueue (\(studyQueue?.lastUpdateTimestamp ?? NSDate.distantPast())) from database complete.  Needs refreshing? \(self.apiDataNeedsRefresh)")
                    if self.apiDataNeedsRefresh {
                        self.updateStudyQueueTimer?.fire()
                    }
                }
            } catch {
                // Database errors are fatal
                fatalError("DashboardViewController: Failed to fetch latest study queue due to error: \(error)")
            }
        }
    }
    
    func fetchStudyQueueFromNetwork(forced forced: Bool, afterDelay delay: NSTimeInterval? = nil) {
        guard let apiKey = ApplicationSettings.apiKey else {
            fatalError("API Key must be set to fetch study queue")
        }
        
        if !forced && self.dataRefreshOperation != nil {
            DDLogInfo("Not restarting study queue refresh as an operation is already running and force flag not set")
            return
        }
        
        DDLogInfo("Checking whether study queue needs refreshed (forced? \(forced))")
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let databaseQueue = delegate.databaseQueue
        let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
        let operation = GetDashboardDataOperation(resolver: resolver, databaseQueue: databaseQueue, forcedFetch: forced, isInteractive: true, initialDelay: delay)
        
        // Study queue
        let studyQueueObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let userInformation = try! UserInformation.coder.loadFromDatabase(database)
                let studyQueue = try! StudyQueue.coder.loadFromDatabase(database)
                dispatch_async(dispatch_get_main_queue()) {
                    self?.userInformation = userInformation
                    self?.studyQueue = studyQueue
                }
            }
        }
        
        operation.studyQueueOperation.addObserver(studyQueueObserver)
        
        // Level progression
        let levelProgressionObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let levelProgression = try! LevelProgression.coder.loadFromDatabase(database)
                dispatch_async(dispatch_get_main_queue()) {
                    self?.levelProgression = levelProgression
                }
            }
        }
        
        operation.levelProgressionOperation.addObserver(levelProgressionObserver)
        
        // SRS Distribution
        let srsDistributionObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let srsDistribution = try! SRSDistribution.coder.loadFromDatabase(database)
                dispatch_async(dispatch_get_main_queue()) {
                    self?.srsDistribution = srsDistribution
                }
            }
        }
        
        operation.srsDistributionOperation.addObserver(srsDistributionObserver)
        
        // SRS Data
        let srsDataObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let levelData = try! SRSDataItemCoder.levelTimeline(database)
                dispatch_async(dispatch_get_main_queue()) {
                    self?.levelData = levelData
                }
            }
        }
        
        operation.srsDataItemOperation.addObserver(srsDataObserver)
        
        // Operation finish
        let observer = BlockObserver(
            startHandler: { operation in
                DDLogInfo("Fetching study queue (request ID \(ObjectIdentifier(operation).uintValue))...")
            },
            finishHandler: { [weak self] (operation, errors) in
                let fatalErrors = errors.filterNonFatalErrors()
                DDLogInfo("Study queue fetch complete (request ID \(ObjectIdentifier(operation).uintValue)): \(fatalErrors)")
                let operation = operation as! GetDashboardDataOperation
                dispatch_async(dispatch_get_main_queue()) {
                    // If this operation represents the currently tracked operation, then set to nil to mark as done
                    if operation === self?.dataRefreshOperation {
                        self?.dataRefreshOperation = nil
                    }
                }
            })
        operation.addObserver(observer)
        DDLogInfo("Enqueuing fetch of latest study queue")
        
        delegate.operationQueue.addOperation(operation)
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.dataRefreshOperation = operation
        }
    }
    
    func fetchStudyQueueFromNetworkInBackground(forced forced: Bool, afterDelay delay: NSTimeInterval? = nil) {
        dispatch_async(dispatch_get_global_queue(forced ? QOS_CLASS_USER_INITIATED : QOS_CLASS_UTILITY, 0)) { [weak self] in
            self?.fetchStudyQueueFromNetwork(forced: forced, afterDelay: delay)
        }
    }
    
    // MARK: - Timer Callbacks
    
    func updateUITimerDidFire(timer: NSTimer) {
        guard let studyQueue = self.studyQueue else {
            return
        }
        
        setTimeToNextReview(studyQueue)
    }
    
    func updateStudyQueueTimerDidFire(timer: NSTimer) {
        // Don't schedule another fetch if one is still running
        guard self.overallProgress?.finished ?? true else { return }
        fetchStudyQueueFromNetworkInBackground(forced: false)
    }
    
    func startTimers() {
        updateUITimer = {
            // Find out when the start of the next minute is
            let referenceDate = NSDate()
            let calendar = NSCalendar.autoupdatingCurrentCalendar()
            let components = NSDateComponents()
            components.second = -calendar.component(.Second, fromDate: referenceDate)
            components.minute = 1
            // Schedule timer for the top of every minute
            let nextFireTime = calendar.dateByAddingComponents(components, toDate: referenceDate, options: [])!
            let timer = NSTimer(fireDate: nextFireTime, interval: 60, target: self, selector: "updateUITimerDidFire:", userInfo: nil, repeats: true)
            timer.tolerance = 1
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
            return timer
            }()
        updateStudyQueueTimer = {
            let nextFetchTime = WaniKaniAPI.nextRefreshTimeFromNow()
            
            DDLogInfo("Will fetch study queue at \(nextFetchTime)")
            let timer = NSTimer(fireDate: nextFetchTime, interval: NSTimeInterval(WaniKaniAPI.updateMinuteCount * 60), target: self, selector: "updateStudyQueueTimerDidFire:", userInfo: nil, repeats: true)
            timer.tolerance = 20
            NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
            return timer
            }()
        
        // Database could have been updated from a background fetch.  Refresh it now in case.
        DDLogDebug("Enqueuing fetch of latest StudyQueue from database")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.fetchStudyQueueFromDatabase()
        }
    }
    
    func killTimers() {
        updateUITimer = nil
        updateStudyQueueTimer = nil
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(controller: WebViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        if controller.URL == WaniKaniURLs.reviewSession || controller.URL == WaniKaniURLs.lessonSession {
            fetchStudyQueueFromNetworkInBackground(forced: true, afterDelay: 1)
        }
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(controller: WKWebViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clearColor()
        label.opaque = false
        label.textColor = UIColor.blackColor()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let visualEffectVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        visualEffectVibrancyView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        visualEffectVibrancyView.contentView.addSubview(label)
        visualEffectVibrancyView.contentView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-|", options: [], metrics: nil, views: ["label": label]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]", options: [], metrics: nil, views: ["label": label]))
        
        switch tableViewSection {
        case .CurrentlyAvailable: label.text = "Currently Available"
        case .NextReview: label.text = "Upcoming Reviews"
        case .LevelProgress:
            if let level = userInformation?.level {
                label.text = "Level \(level) Progress"
            } else {
                label.text = "Level Progress"
            }
        case .SRSDistribution: label.text = "SRS Item Distribution"
        case .Links: label.text = "Links"
        }
        
        return visualEffectVibrancyView
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch (tableViewSection, indexPath.row) {
        case (.CurrentlyAvailable, 0): // Lessons
            showLessonsView()
        case (.CurrentlyAvailable, 1): // Reviews
            showReviewsView()
        case (.Links, 0): // Web Dashboard
            let vc = WKWebViewController.forURL(WaniKaniURLs.dashboard, configBlock: wkWebViewControllerCommonConfiguration)
            presentViewController(vc, animated: true, completion: nil)
        case (.Links, 1): // Community Centre
            let vc = WKWebViewController.forURL(WaniKaniURLs.communityCentre, configBlock: wkWebViewControllerCommonConfiguration)
            presentViewController(vc, animated: true, completion: nil)
        default: break
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEnterForeground:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        let backgroundView = UIView(frame: tableView.frame)
        let imageView = UIImageView(image: UIImage(named: "Header"))
        imageView.contentMode = .ScaleAspectFill
        imageView.frame = backgroundView.frame
        backgroundView.addSubview(imageView)
        let visualEffectBlurView = UIVisualEffectView(effect: blurEffect)
        visualEffectBlurView.frame = imageView.frame
        visualEffectBlurView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        backgroundView.addSubview(visualEffectBlurView)
        tableView.backgroundView = backgroundView
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        
        apprenticeCell.imageView?.image = apprenticeCell.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        guruCell.imageView?.image = guruCell.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        masterCell.imageView?.image = masterCell.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        enlightenedCell.imageView?.image = enlightenedCell.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        burnedCell.imageView?.image = burnedCell.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate)
        
        // Ensure the refresh control is positioned on top of the background view
        if let refreshControl = self.refreshControl where refreshControl.layer.zPosition <= tableView.backgroundView!.layer.zPosition {
            tableView.backgroundView!.layer.zPosition = refreshControl.layer.zPosition - 1
        }
        
        if let toolbar = self.navigationController?.toolbar {
            progressView = UIProgressView(progressViewStyle: .Default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.trackTintColor = UIColor.clearColor()
            progressView.progress = 0
            progressView.alpha = 0
            toolbar.addSubview(progressView)
            NSLayoutConstraint(item: progressView, attribute: .Top, relatedBy: .Equal, toItem: toolbar, attribute: .Top, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressView, attribute: .Leading, relatedBy: .Equal, toItem: toolbar, attribute: .Leading, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressView, attribute: .Trailing, relatedBy: .Equal, toItem: toolbar, attribute: .Trailing, multiplier: 1, constant: 0).active = true
            
            var items = self.toolbarItems ?? []
            
            items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
            
            let toolbarView = UIView(frame: toolbar.bounds)
            toolbarView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            let statusView = UIView(frame: CGRect.zero)
            statusView.translatesAutoresizingMaskIntoConstraints = false
            toolbarView.addSubview(statusView)
            NSLayoutConstraint(item: statusView, attribute: .CenterX, relatedBy: .Equal, toItem: toolbarView, attribute: .CenterX, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: statusView, attribute: .CenterY, relatedBy: .Equal, toItem: toolbarView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
            
            progressDescriptionLabel = UILabel()
            progressDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            progressDescriptionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            progressDescriptionLabel.backgroundColor = UIColor.clearColor()
            progressDescriptionLabel.textColor = UIColor.blackColor()
            progressDescriptionLabel.textAlignment = .Center
            statusView.addSubview(progressDescriptionLabel)
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .Top, relatedBy: .Equal, toItem: statusView, attribute: .Top, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .Leading, relatedBy: .Equal, toItem: statusView, attribute: .Leading, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .Trailing, relatedBy: .Equal, toItem: statusView, attribute: .Trailing, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .Bottom, relatedBy: .LessThanOrEqual, toItem: statusView, attribute: .Bottom, multiplier: 1, constant: 0).active = true
            
            progressAdditionalDescriptionLabel = UILabel()
            progressAdditionalDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            progressAdditionalDescriptionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            progressAdditionalDescriptionLabel.backgroundColor = UIColor.clearColor()
            progressAdditionalDescriptionLabel.textColor = UIColor.darkGrayColor()
            progressAdditionalDescriptionLabel.textAlignment = .Center
            statusView.addSubview(progressAdditionalDescriptionLabel)
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .Leading, relatedBy: .Equal, toItem: statusView, attribute: .Leading, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .Trailing, relatedBy: .Equal, toItem: statusView, attribute: .Trailing, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .Bottom, relatedBy: .Equal, toItem: statusView, attribute: .Bottom, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .Top, relatedBy: .Equal, toItem: progressDescriptionLabel, attribute: .Bottom, multiplier: 1, constant: 0).active = true
            
            let statusViewBarButtonItem = UIBarButtonItem(customView: toolbarView)
            items.append(statusViewBarButtonItem)
            
            items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
            
            self.setToolbarItems(items, animated: false)
        }
        
        updateUI()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let apiKey = ApplicationSettings.apiKey where !apiKey.isEmpty else {
            DDLogDebug("Dashboard view has no API key.  Dismissing back to home screen.")
            dismissViewControllerAnimated(false, completion: nil)
            return
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // The view will be dismissed if there's no API key set (possibly because it was cleared in app settings)
        // Don't bother starting timers in this case.
        guard let apiKey = ApplicationSettings.apiKey where !apiKey.isEmpty else {
            DDLogDebug("Dashboard view has no API key.  Not starting timers.")
            return
        }
        
        startTimers()
        updateUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        killTimers()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case SegueIdentifiers.radicalsProgress:
            if let vc = segue.destinationContentViewController as? SRSDataItemCollectionViewController {
                self.databaseQueue.inDatabase { database in
                    do {
                        if let userInformation = try UserInformation.coder.loadFromDatabase(database) {
                            let radicals = try Radical.coder.loadFromDatabase(database, forLevel: userInformation.level)
                            vc.setSRSDataItems(radicals.map { $0 as SRSDataItem }, withTitle: "Radicals")
                        }
                    } catch {
                        DDLogWarn("Failed to get radicals for current level: \(error)")
                    }
                }
            }
        case SegueIdentifiers.kanjiProgress:
            if let vc = segue.destinationContentViewController as? SRSDataItemCollectionViewController {
                self.databaseQueue.inDatabase { database in
                    do {
                        if let userInformation = try UserInformation.coder.loadFromDatabase(database) {
                            let kanji = try Kanji.coder.loadFromDatabase(database, forLevel: userInformation.level)
                            vc.setSRSDataItems(kanji.map { $0 as SRSDataItem }, withTitle: "Kanji")
                        }
                    } catch {
                        DDLogWarn("Failed to get radicals for current level: \(error)")
                    }
                }
            }
        case SegueIdentifiers.levelDataChart:
            if let vc = segue.destinationContentViewController as? LevelChartViewController {
                vc.levelData = self.levelData
            }
        default: break
        }
    }
    
    private func webViewControllerCommonConfiguration(webViewController: WebViewController) {
        webViewController.delegate = self
    }
    
    private func wkWebViewControllerCommonConfiguration(webViewController: WKWebViewController) {
        webViewController.delegate = self
    }
    
    private func presentReviewPageWebViewControllerForURL(URL: NSURL) {
        let vc = WaniKaniReviewPageWebViewController.forURL(URL, configBlock: webViewControllerCommonConfiguration)
        if self.dataRefreshOperation != nil {
            // Cancel data refresh operation because we're just going to restart it when the web view is dismissed
            DDLogDebug("Cancelling data refresh operation")
            self.dataRefreshOperation = nil
        }
        presentViewController(vc, animated: true, completion: nil)
    }
    
    // MARK: - Background transition
    
    func didEnterBackground(notification: NSNotification) {
        killTimers()
    }
    
    func didEnterForeground(notification: NSNotification) {
        startTimers()
        updateUI()
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &dashboardViewControllerObservationContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateProgress()
        }
    }
}
