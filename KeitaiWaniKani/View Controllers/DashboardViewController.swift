//
//  DashboardViewController.swift
//  AlliCrab
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
        static let appSettings = "Show App Settings"
        static let radicalsProgress = "Show Radicals Progress"
        static let kanjiProgress = "Show Kanji Progress"
        static let levelDataChart = "Show Level Data Chart"
    }
    
    private enum TableViewSection: Int {
        case currentlyAvailable = 0, nextReview = 1, levelProgress = 2, srsDistribution = 3, links = 4
    }
    
    // MARK: - Properties
    
    var progressDescriptionLabel: UILabel!
    var progressAdditionalDescriptionLabel: UILabel!
    var progressView: UIProgressView!
    
    private var updateUITimer: Timer? {
        willSet {
            updateUITimer?.invalidate()
        }
    }
    
    private var updateStudyQueueTimer: Timer? {
        willSet {
            updateStudyQueueTimer?.invalidate()
        }
    }
    
    private var userInformation: UserInformation? {
        didSet {
            if userInformation != oldValue {
                self.updateUI(userInformation: userInformation)
            }
        }
    }
    
    private var studyQueue: StudyQueue? {
        didSet {
            if studyQueue != oldValue {
                self.updateUI(studyQueue: studyQueue)
            }
        }
    }
    
    private var levelProgression: LevelProgression? {
        didSet {
            if levelProgression != oldValue {
                self.updateUI(levelProgression: levelProgression)
            }
        }
    }
    
    private var srsDistribution: SRSDistribution? {
        didSet {
            if srsDistribution != oldValue {
                self.updateUI(srsDistribution: srsDistribution)
            }
        }
    }
    
    private var levelData: LevelData? {
        didSet {
            if levelData != oldValue {
                self.updateUI(levelData: levelData)
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
            
            if formerProgress.fractionCompleted < 1 && formerProgress.isCancellable {
                DDLogDebug("Cancelling incomplete operation \(UInt(bitPattern: ObjectIdentifier(formerDataRefreshOperation)))")
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
    
    private var overallProgress: Progress? {
        return dataRefreshOperation?.progress
    }
    
    private var progressViewIsHidden: Bool {
        return progressView == nil || progressView?.alpha == 0
    }
    
    private let blurEffect = UIBlurEffect(style: .extraLight)
    
    private var headerFont: UIFont {
        if #available(iOS 9.0, *) {
            return UIFont.preferredFont(forTextStyle: .title2)
        } else {
            let headlineFont = UIFont.preferredFont(forTextStyle: .body)
            let pointSize = headlineFont.pointSize * 1.3
            return headlineFont.withSize(pointSize)
        }
    }
    
    /// Formats percentages in truncated to whole percents (as the WK dashboard does)
    private lazy var percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .down
        formatter.roundingIncrement = 0.01
        return formatter
    }()
    
    private lazy var lastRefreshTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private lazy var averageLevelDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.allowsFractionalUnits = true
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    private var databaseManager: DatabaseManager!
    private var databaseQueue: FMDatabaseQueue { return databaseManager.databaseQueue }
    
    private var operationQueue: OperationKit.OperationQueue!
    
    // MARK: - Outlets
    
    // MARK: Currently Available
    
    @IBOutlet weak var pendingLessonsLabel: UILabel!
    @IBOutlet weak var reviewTitleLabel: UILabel!
    @IBOutlet weak var reviewCountLabel: UILabel!
    @IBOutlet weak var reviewTimeRemainingLabel: UILabel!
    
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
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        fetchStudyQueueFromNetworkInBackground(forced: true)
    }
    
    // Unwind segue when web browser is dismissed
    @IBAction func forceRefreshStudyQueue(_ segue: UIStoryboardSegue) {
        fetchStudyQueueFromNetworkInBackground(forced: true)
    }
    
    func showLessonsView() {
        presentReviewPageWebViewController(url: WaniKaniURLs.lessonSession)
    }
    
    func showReviewsView() {
        presentReviewPageWebViewController(url: WaniKaniURLs.reviewSession)
    }
    
    func showSettings() {
        performSegue(withIdentifier: SegueIdentifiers.appSettings, sender: nil)
    }
    
    // MARK: - Update UI
    
    func updateUI() {
        updateUI(studyQueue: studyQueue)
        updateUI(levelProgression: levelProgression)
        updateUI(userInformation: userInformation)
        updateUI(srsDistribution: srsDistribution)
        updateUI(levelData: levelData)
        updateProgress()
    }
    
    // MARK: Progress
    
    func updateProgress() {
        updateProgressLabels()
        updateProgressView()
    }
    
    func updateProgressLabels() {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        // Description label text
        let localizedDescription = overallProgress?.localizedDescription
        if localizedDescription?.isEmpty == false {
            progressDescriptionLabel?.text = localizedDescription
        } else {
            let formattedLastRefreshTime = ApplicationSettings.lastRefreshTime.map { $0.timeIntervalSinceNow > -60 ? "Just Now" : lastRefreshTimeFormatter.string(from: $0) } ?? "Never"
            progressDescriptionLabel?.text = "Updated \(formattedLastRefreshTime)"
        }
        
        // Additional description label text
        if let localizedAdditionalDescription = overallProgress?.localizedAdditionalDescription {
            // Set the text only if it is non-empty.  Otherwise, keep the existing text.
            if !localizedAdditionalDescription.isEmpty {
                progressAdditionalDescriptionLabel?.text = localizedAdditionalDescription
            }
            // Update the visibility based on whether there's text in the label or not
            progressAdditionalDescriptionLabel?.isHidden = progressAdditionalDescriptionLabel?.text?.isEmpty != false
        } else {
            progressAdditionalDescriptionLabel?.text = nil
            progressAdditionalDescriptionLabel?.isHidden = true
        }
    }
    
    func updateProgressView() {
        assert(Thread.isMainThread, "Must be called on the main thread")
        guard let progressView = progressView else { return }
        
        // Progress view visibility
        let shouldHide: Bool
        let fractionCompleted: Float
        if let overallProgress = self.overallProgress {
            shouldHide = overallProgress.finished || overallProgress.isCancelled
            fractionCompleted = Float(overallProgress.fractionCompleted)
        } else {
            shouldHide = true
            fractionCompleted = 0
        }
        
        if !progressViewIsHidden && shouldHide {
            UIView.animate(withDuration: 0.1) {
                progressView.setProgress(1.0, animated: false)
            }
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseIn],
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
    
    func updateUI(studyQueue: StudyQueue?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        guard let studyQueue = self.studyQueue else {
            pendingLessonsLabel.text = "–"
            reviewTitleLabel.text = "Reviews"
            reviewCountLabel.text = "–"
            reviewTimeRemainingLabel.text = nil
            reviewsNextHourLabel.text = "–"
            reviewsNextDayLabel.text = "–"
            return
        }
        
        setCount(studyQueue.lessonsAvailable, forLabel: pendingLessonsLabel, availableColour: self.view.tintColor)
        pendingLessonsLabel.font = UIFont.systemFont(ofSize: 24, weight: studyQueue.lessonsAvailable > 0 ? UIFontWeightRegular : UIFontWeightThin)
        
        setCount(studyQueue.reviewsAvailableNextHour, forLabel: reviewsNextHourLabel)
        setCount(studyQueue.reviewsAvailableNextDay, forLabel: reviewsNextDayLabel)
        
        setTimeToNextReview(studyQueue)
    }
    
    private func setCount(_ count: Int, forLabel label: UILabel?, availableColour: UIColor = .black, unavailableColour: UIColor = .lightGray) {
        guard let label = label else { return }
        
        label.text = NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
        label.textColor = count > 0 ? availableColour : unavailableColour
    }
    
    func setTimeToNextReview(_ studyQueue: StudyQueue) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        switch studyQueue.formattedTimeToNextReview() {
        case .none, .now:
            reviewTitleLabel.text = "Reviews"
            setCount(studyQueue.reviewsAvailable, forLabel: reviewCountLabel, availableColour: self.view.tintColor)
            reviewCountLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightRegular)
            reviewTimeRemainingLabel.text = nil
        case .formattedString(let formattedInterval):
            reviewTitleLabel.text = "Next Review"
            reviewCountLabel.text = studyQueue.formattedNextReviewDate()
            reviewCountLabel.textColor = .black
            reviewCountLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightThin)
            reviewTimeRemainingLabel.text = formattedInterval
        case .unformattedInterval(let secondsUntilNextReview):
            reviewTitleLabel.text = "Next Review"
            reviewCountLabel.text = studyQueue.formattedNextReviewDate()
            reviewCountLabel.textColor = .black
            reviewCountLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFontWeightThin)
            reviewTimeRemainingLabel.text = "\(NumberFormatter.localizedString(from: NSNumber(value: secondsUntilNextReview), number: .decimal))s"
        }
    }
    
    func updateUI(levelProgression: LevelProgression?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        guard let levelProgression = self.levelProgression else {
            return
        }
        
        self.updateLevelProgressCellTo(levelProgression.radicalsProgress, ofTotal: levelProgression.radicalsTotal, percentageCompletionLabel: radicalPercentageCompletionLabel, progressView: radicalProgressView, totalItemCountLabel: radicalTotalItemCountLabel)
        self.updateLevelProgressCellTo(levelProgression.kanjiProgress, ofTotal: levelProgression.kanjiTotal, percentageCompletionLabel: kanjiPercentageCompletionLabel, progressView: kanjiProgressView, totalItemCountLabel: kanjiTotalItemCountLabel)
    }
    
    func updateUI(userInformation: UserInformation?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        self.tableView.reloadSections(IndexSet(integer: TableViewSection.levelProgress.rawValue), with: .none)
    }
    
    func updateLevelProgressCellTo(_ complete: Int, ofTotal total: Int, percentageCompletionLabel: UILabel?, progressView: UIProgressView?, totalItemCountLabel: UILabel?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        let fractionComplete = total == 0 ? 1.0 : Double(complete) / Double(total)
        let formattedFractionComplete = percentFormatter.string(from: NSNumber(value: fractionComplete)) ?? "–%"
        
        percentageCompletionLabel?.text = formattedFractionComplete
        progressView?.setProgress(Float(fractionComplete), animated: true)
        totalItemCountLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: total), number: .decimal)
    }
    
    func updateUI(srsDistribution: SRSDistribution?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        let pairs: [(SRSLevel, UILabel?)] = [
            (.apprentice, apprenticeCell.detailTextLabel),
            (.guru, guruCell.detailTextLabel),
            (.master, masterCell.detailTextLabel),
            (.enlightened, enlightenedCell.detailTextLabel),
            (.burned, burnedCell.detailTextLabel),
            ]
        
        for (srsLevel, label) in pairs {
            let itemCounts = srsDistribution?.countsBySRSLevel[srsLevel] ?? SRSItemCounts.zero
            let formattedCount = NumberFormatter.localizedString(from: NSNumber(value: itemCounts.total), number: .decimal)
            label?.text = formattedCount
        }
        
        self.tableView.reloadSections(IndexSet(integer: TableViewSection.srsDistribution.rawValue), with: .none)
    }
    
    func updateUI(levelData: LevelData?) {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        defer { self.tableView.reloadSections(IndexSet(integer: TableViewSection.levelProgress.rawValue), with: .none) }
        
        guard let levelData = levelData, let projectedCurrentLevel = levelData.projectedCurrentLevel else {
            averageLevelTimeCell.detailTextLabel?.text = "–"
            currentLevelTimeCell.detailTextLabel?.text = "–"
            currentLevelTimeRemainingCell.textLabel?.text = "Level Up In"
            currentLevelTimeRemainingCell.detailTextLabel?.text = "–"
            return
        }
        
        if let averageLevelDuration = levelData.stats?.mean {
            let formattedAverageLevelDuration = averageLevelDurationFormatter.string(from: averageLevelDuration) ?? "\(NumberFormatter.localizedString(from: NSNumber(value: averageLevelDuration), number: .decimal))s"
            averageLevelTimeCell.detailTextLabel?.text = formattedAverageLevelDuration
        }
        
        let startDate = projectedCurrentLevel.startDate
        let timeSinceLevelStart = -startDate.timeIntervalSinceNow
        let formattedTimeSinceLevelStart = averageLevelDurationFormatter.string(from: timeSinceLevelStart) ?? "\(NumberFormatter.localizedString(from: NSNumber(value: timeSinceLevelStart), number: .decimal))s"
        currentLevelTimeCell.detailTextLabel?.text = formattedTimeSinceLevelStart
        
        let expectedEndDate: Date
        let endDateByProjection = projectedCurrentLevel.endDate
        if projectedCurrentLevel.endDateBasedOnLockedItem {
            let endDateByEstimate = startDate.addingTimeInterval(levelData.stats?.mean ?? 0)
            expectedEndDate = max(endDateByEstimate, endDateByProjection)
        } else {
            expectedEndDate = endDateByProjection
        }
        
        let timeUntilLevelCompletion = expectedEndDate.timeIntervalSinceNow
        let formattedTimeUntilLevelCompletion = timeUntilLevelCompletion <= 0 ? "–" : averageLevelDurationFormatter.string(from: timeUntilLevelCompletion) ?? "\(NumberFormatter.localizedString(from: NSNumber(value: timeUntilLevelCompletion), number: .decimal))s"
        
        currentLevelTimeRemainingCell.textLabel?.text = projectedCurrentLevel.endDateBasedOnLockedItem ? "Level Up In (Estimated)" : "Level Up In"
        currentLevelTimeRemainingCell.detailTextLabel?.text = formattedTimeUntilLevelCompletion
    }
    
    // MARK: - Data Fetch
    
    func fetchStudyQueueFromDatabase() {
        databaseQueue.inDatabase { database in
            do {
                let userInformation = try UserInformation.coder.load(from: database)
                let studyQueue = try StudyQueue.coder.load(from: database)
                let levelProgression = try LevelProgression.coder.load(from: database)
                let srsDistribution = try SRSDistribution.coder.load(from: database)
                let levelData = try SRSDataItemCoder.levelTimeline(database)
                DispatchQueue.main.async {
                    self.userInformation = userInformation
                    self.studyQueue = studyQueue
                    self.levelProgression = levelProgression
                    self.srsDistribution = srsDistribution
                    self.levelData = levelData
                    self.updateProgress()
                    
                    DDLogDebug("Fetch of latest StudyQueue (\(studyQueue?.lastUpdateTimestamp ?? Date.distantPast)) from database complete.  Needs refreshing? \(self.apiDataNeedsRefresh)")
                    if self.apiDataNeedsRefresh {
                        self.fetchStudyQueueFromNetworkInBackground(forced: true)
                    }
                }
            } catch {
                // Database errors are fatal
                fatalError("DashboardViewController: Failed to fetch latest study queue due to error: \(error)")
            }
        }
    }
    
    func fetchStudyQueueFromNetwork(forced: Bool, afterDelay delay: TimeInterval? = nil) {
        guard let apiKey = ApplicationSettings.apiKey else {
            fatalError("API Key must be set to fetch study queue")
        }
        
        if !forced && self.dataRefreshOperation != nil {
            DDLogInfo("Not restarting study queue refresh as an operation is already running and force flag not set")
            return
        }
        
        DDLogInfo("Checking whether study queue needs refreshed (forced? \(forced))")
        let databaseQueue = self.databaseQueue
        let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
        let operation = GetDashboardDataOperation(resolver: resolver, databaseQueue: databaseQueue, forcedFetch: forced, isInteractive: true, initialDelay: delay)
        
        // Study queue
        let studyQueueObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let userInformation = try! UserInformation.coder.load(from: database)
                let studyQueue = try! StudyQueue.coder.load(from: database)
                DispatchQueue.main.async {
                    self?.userInformation = userInformation
                    self?.studyQueue = studyQueue
                }
            }
        }
        
        operation.studyQueueOperation.addObserver(studyQueueObserver)
        
        // Level progression
        let levelProgressionObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let levelProgression = try! LevelProgression.coder.load(from: database)
                DispatchQueue.main.async {
                    self?.levelProgression = levelProgression
                }
            }
        }
        
        operation.levelProgressionOperation.addObserver(levelProgressionObserver)
        
        // SRS Distribution
        let srsDistributionObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let srsDistribution = try! SRSDistribution.coder.load(from: database)
                DispatchQueue.main.async {
                    self?.srsDistribution = srsDistribution
                }
            }
        }
        
        operation.srsDistributionOperation.addObserver(srsDistributionObserver)
        
        // SRS Data
        let srsDataObserver = BlockObserver { [weak self] _ in
            databaseQueue.inDatabase { database in
                let levelData = try! SRSDataItemCoder.levelTimeline(database)
                DispatchQueue.main.async {
                    self?.levelData = levelData
                }
            }
        }
        
        operation.srsDataItemOperation.addObserver(srsDataObserver)
        
        // Operation finish
        let observer = BlockObserver(
            startHandler: { operation in DDLogInfo("Fetching study queue (request ID \(UInt(bitPattern: ObjectIdentifier(operation))))...") },
            finishHandler: { [weak self] (operation, errors) in
                let fatalErrors = errors.filterNonFatalErrors()
                DDLogInfo("Study queue fetch complete (request ID \(UInt(bitPattern: ObjectIdentifier(operation)))): \(fatalErrors)")
                
                let operation = operation as! GetDashboardDataOperation
                DispatchQueue.main.async {
                    // If this operation represents the currently tracked operation, then set to nil to mark as done
                    if operation === self?.dataRefreshOperation {
                        self?.dataRefreshOperation = nil
                    }
                }
                
                if errors.contains(where: { if case WaniKaniAPIError.userNotFound = $0 { return true } else { return false } }) {
                    DispatchQueue.main.async {
                        DDLogWarn("Logging out due to user not found")
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        
                        delegate.performLogOut()
                        
                        // Pop to home screen
                        self?.navigationController?.dismiss(animated: true) {
                            UIApplication.shared.keyWindow?.rootViewController?.showAlert(title: "Invalid API Key", message: "WaniKani has reported that your API key is now invalid.  Please log in again.")
                        }
                    }
                }
            }
        )
        operation.addObserver(observer)
        DDLogInfo("Enqueuing fetch of latest study queue")
        
        operationQueue.addOperation(operation)
        
        DispatchQueue.main.async { [weak self] in
            self?.dataRefreshOperation = operation
        }
    }
    
    func fetchStudyQueueFromNetworkInBackground(forced: Bool, afterDelay delay: TimeInterval? = nil) {
        DispatchQueue.global(qos: forced ? .userInitiated : .utility).async { [weak self] in
            self?.fetchStudyQueueFromNetwork(forced: forced, afterDelay: delay)
        }
    }
    
    // MARK: - Timer Callbacks
    
    func updateUITimerDidFire(_ timer: Timer) {
        guard let studyQueue = self.studyQueue else {
            return
        }
        
        setTimeToNextReview(studyQueue)
    }
    
    func updateStudyQueueTimerDidFire(_ timer: Timer) {
        // Don't schedule another fetch if one is still running
        guard self.overallProgress?.finished ?? true else { return }
        fetchStudyQueueFromNetworkInBackground(forced: false)
    }
    
    func startTimers() {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        updateUITimer = {
            // Find out when the start of the next minute is
            let referenceDate = Date()
            let calendar = Calendar.autoupdatingCurrent
            var components = DateComponents()
            components.second = -calendar.component(.second, from: referenceDate)
            components.minute = 1
            // Schedule timer for the top of every minute
            let nextFireTime = calendar.date(byAdding: components, to: referenceDate)!
            let timer = Timer(fireAt: nextFireTime, interval: 60, target: self, selector: #selector(updateUITimerDidFire(_:)), userInfo: nil, repeats: true)
            timer.tolerance = 1
            RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
            return timer
        }()
        updateStudyQueueTimer = {
            let nextFetchTime = WaniKaniAPI.nextRefreshTimeFromNow()
            
            DDLogInfo("Will fetch study queue at \(nextFetchTime)")
            let timer = Timer(fireAt: nextFetchTime, interval: TimeInterval(WaniKaniAPI.updateMinuteCount * 60), target: self, selector: #selector(updateStudyQueueTimerDidFire(_:)), userInfo: nil, repeats: true)
            timer.tolerance = 20
            RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
            return timer
        }()
        
        // Database could have been updated from a background fetch.  Refresh it now in case.
        DDLogDebug("Enqueuing fetch of latest StudyQueue from database")
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchStudyQueueFromDatabase()
        }
    }
    
    func killTimers() {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        updateUITimer = nil
        updateStudyQueueTimer = nil
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
        controller.dismiss(animated: true, completion: nil)
        if controller.url == WaniKaniURLs.reviewSession || controller.url == WaniKaniURLs.lessonSession {
            fetchStudyQueueFromNetworkInBackground(forced: true, afterDelay: 1)
        }
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(_ controller: WKWebViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let label = UILabel()
        label.font = headerFont
        label.text = "Currently Available"
        label.sizeToFit()
        
        return label.bounds.height + 16
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        label.backgroundColor = .clear
        label.isOpaque = false
        label.textColor = .black
        label.font = headerFont
        
        switch tableViewSection {
        case .currentlyAvailable:
            label.text = "Currently Available"
        case .nextReview:
            label.text = "Upcoming Reviews"
        case .levelProgress:
            if let level = userInformation?.level {
                label.text = "Level \(level) Progress"
            } else {
                label.text = "Level Progress"
            }
        case .srsDistribution:
            label.text = "SRS Item Distribution"
        case .links:
            label.text = "Links"
        }
        
        let containerView: UIView
        if UIAccessibilityIsReduceTransparencyEnabled() {
            containerView = UIView(frame: .zero)
            containerView.addSubview(label)
        } else {
            let visualEffectVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
            visualEffectVibrancyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            visualEffectVibrancyView.contentView.addSubview(label)
            visualEffectVibrancyView.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            visualEffectVibrancyView.contentView.layoutMargins.left = tableView.separatorInset.left / 2
            containerView = visualEffectVibrancyView
        }
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[label]-|", options: [], metrics: nil, views: ["label": label]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]", options: [], metrics: nil, views: ["label": label]))
        
        return containerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch (tableViewSection, indexPath.row) {
        case (.currentlyAvailable, 0): // Lessons
            showLessonsView()
        case (.currentlyAvailable, 1): // Reviews
            showReviewsView()
        case (.links, 0): // Web Dashboard
            let vc = WKWebViewController.wrapped(url: WaniKaniURLs.dashboard) { $0.delegate = self }
            present(vc, animated: true, completion: nil)
        case (.links, 1): // Community Centre
            let vc = WKWebViewController.wrapped(url: WaniKaniURLs.communityCentre) { $0.delegate = self }
            present(vc, animated: true, completion: nil)
        default: break
        }
        
        DispatchQueue.main.async {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        databaseManager = delegate.databaseManager
        operationQueue = delegate.operationQueue

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reduceTransparencyStatusDidChange(_:)), name: NSNotification.Name.UIAccessibilityReduceTransparencyStatusDidChange, object: nil)
        
        let backgroundView = UIView(frame: tableView.frame)
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        let imageView = UIImageView(image: UIImage(named: "Header"))
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.contentMode = .scaleAspectFill
        imageView.frame = backgroundView.frame
        backgroundView.addSubview(imageView)
        let visualEffectBlurView = UIVisualEffectView(effect: blurEffect)
        visualEffectBlurView.frame = imageView.frame
        visualEffectBlurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.addSubview(visualEffectBlurView)
        let darkenView = UIView(frame: visualEffectBlurView.frame)
        darkenView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        darkenView.alpha = 0.1
        darkenView.backgroundColor = ApplicationSettings.globalTintColor
        visualEffectBlurView.contentView.addSubview(darkenView)
        tableView.backgroundView = backgroundView
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
        
        apprenticeCell.imageView?.image = apprenticeCell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        guruCell.imageView?.image = guruCell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        masterCell.imageView?.image = masterCell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        enlightenedCell.imageView?.image = enlightenedCell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        burnedCell.imageView?.image = burnedCell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        
        // Ensure the refresh control is positioned on top of the background view
        if let refreshControl = self.refreshControl, refreshControl.layer.zPosition <= tableView.backgroundView!.layer.zPosition {
            tableView.backgroundView!.layer.zPosition = refreshControl.layer.zPosition - 1
        }
        
        if let toolbar = self.navigationController?.toolbar {
            progressView = UIProgressView(progressViewStyle: .default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.trackTintColor = .clear
            progressView.progress = 0
            progressView.alpha = 0
            toolbar.addSubview(progressView)
            NSLayoutConstraint(item: progressView, attribute: .top, relatedBy: .equal, toItem: toolbar, attribute: .top, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: toolbar, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: toolbar, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            
            var items = self.toolbarItems ?? []
            
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            
            let toolbarView = UIView(frame: toolbar.bounds)
            toolbarView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            let statusView = UIView(frame: CGRect.zero)
            statusView.translatesAutoresizingMaskIntoConstraints = false
            toolbarView.addSubview(statusView)
            NSLayoutConstraint(item: statusView, attribute: .centerX, relatedBy: .equal, toItem: toolbarView, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: statusView, attribute: .centerY, relatedBy: .equal, toItem: toolbarView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
            
            progressDescriptionLabel = UILabel()
            progressDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            progressDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
            progressDescriptionLabel.backgroundColor = .clear
            progressDescriptionLabel.textColor = .black
            progressDescriptionLabel.textAlignment = .center
            statusView.addSubview(progressDescriptionLabel)
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .top, relatedBy: .equal, toItem: statusView, attribute: .top, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .leading, relatedBy: .equal, toItem: statusView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .trailing, relatedBy: .equal, toItem: statusView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressDescriptionLabel, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: statusView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            
            progressAdditionalDescriptionLabel = UILabel()
            progressAdditionalDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            progressAdditionalDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
            progressAdditionalDescriptionLabel.backgroundColor = .clear
            progressAdditionalDescriptionLabel.textColor = .darkGray
            progressAdditionalDescriptionLabel.textAlignment = .center
            statusView.addSubview(progressAdditionalDescriptionLabel)
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .leading, relatedBy: .equal, toItem: statusView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .trailing, relatedBy: .equal, toItem: statusView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .bottom, relatedBy: .equal, toItem: statusView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressAdditionalDescriptionLabel, attribute: .top, relatedBy: .equal, toItem: progressDescriptionLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            
            let statusViewBarButtonItem = UIBarButtonItem(customView: toolbarView)
            items.append(statusViewBarButtonItem)
            
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            
            self.setToolbarItems(items, animated: false)
        }
        
        updateUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let apiKey = ApplicationSettings.apiKey, !apiKey.isEmpty else {
            DDLogDebug("Dashboard view has no API key.  Dismissing back to home screen.")
            dismiss(animated: false, completion: nil)
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // The view will be dismissed if there's no API key set (possibly because it was cleared in app settings)
        // Don't bother starting timers in this case.
        guard let apiKey = ApplicationSettings.apiKey, !apiKey.isEmpty else {
            DDLogDebug("Dashboard view has no API key.  Not starting timers.")
            return
        }
        
        startTimers()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        killTimers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case SegueIdentifiers.radicalsProgress:
            if let vc = segue.destinationContentViewController as? SRSDataItemCollectionViewController {
                self.databaseQueue.inDatabase { database in
                    do {
                        if let userInformation = try UserInformation.coder.load(from: database) {
                            let radicals = try Radical.coder.load(from: database, level: userInformation.level)
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
                        if let userInformation = try UserInformation.coder.load(from: database) {
                            let kanji = try Kanji.coder.load(from: database, level: userInformation.level)
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
    
    private func presentReviewPageWebViewController(url: URL) {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: url) { $0.delegate = self }
        
        if self.dataRefreshOperation != nil {
            // Cancel data refresh operation because we're just going to restart it when the web view is dismissed
            DDLogDebug("Cancelling data refresh operation")
            self.dataRefreshOperation = nil
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Background transition
    
    func didEnterBackground(_ notification: Notification) {
        killTimers()
    }
    
    func didEnterForeground(_ notification: Notification) {
        startTimers()
        updateUI()
    }
    
    func reduceTransparencyStatusDidChange(_ notification: Notification) {
        tableView.reloadData()
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &dashboardViewControllerObservationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        DispatchQueue.main.async {
            self.updateProgress()
        }
    }
}
