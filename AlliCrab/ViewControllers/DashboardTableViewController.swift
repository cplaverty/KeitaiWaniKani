//
//  DashboardTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class DashboardTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case header = "DashboardHeader"
        case numericDetailLarge = "NumericDetailLarge"
        case reviewTime = "ReviewTime"
        case reviewTimeline = "ReviewTimeline"
        case levelProgression = "LevelProgression"
        case srsProgress = "SRSProgress"
        case numericDetail = "NumericDetail"
        case durationDetail = "DurationDetail"
        case webLink = "WebLink"
    }
    
    private enum SegueIdentifier: String {
        case settings = "Settings"
        case reviewTimeline = "ReviewTimeline"
        case assignmentProgression = "AssignmentProgression"
        case srsProgressDetail = "SRSProgressDetail"
    }
    
    private enum TableViewSection: Int {
        case available = 0, upcomingReviews, levelProgression, srsDistribution, links, count
    }
    
    // MARK: - Properties
    
    private let minimumFetchInterval = 15 * .oneMinute
    
    private let lastUpdateDateRelativeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.formattingContext = .middleOfSentence
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.minute]
        return formatter
    }()
    
    private let lastUpdateDateAbsoluteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var resourceRepository: ResourceRepository!
    
    private let backgroundBlurEffectStyle = UIBlurEffectStyle.extraLight
    
    private var userInformation: UserInformation?
    private var studyQueue: StudyQueue?
    private var levelProgression: CurrentLevelProgression?
    private var srsDistribution: SRSDistribution?
    private var levelTimeline: LevelData?
    
    private var updateUITimer: Timer?
    private var notificationObservers: [NSObjectProtocol]?
    private var progressContainerView: ProgressReportingBarButtonItemView!
    private var shouldForceDataReload = false
    
    // MARK: - Initialisers
    
    deinit {
        updateUITimer?.invalidate()
        if let notificationObservers = notificationObservers {
            if #available(iOS 10.0, *) {
                os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
            }
            notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
        }
        notificationObservers = nil
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        updateData(minimumFetchInterval: 0, showAlertOnErrors: true)
    }
    
    @IBAction func presentLessonsViewController() {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: WaniKaniURL.lessonSession) { controller in
            controller.delegate = self
        }
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func presentReviewsViewController() {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: WaniKaniURL.reviewSession) { controller in
            controller.delegate = self
        }
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func presentSettingsViewController() {
        performSegue(withIdentifier: SegueIdentifier.settings.rawValue, sender: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .available:
            return "Currently Available"
        case .upcomingReviews:
            return "Upcoming Reviews"
        case .levelProgression:
            if let level = userInformation?.level {
                return "Level \(level) Progress"
            } else {
                return "Level Progress"
            }
        case .srsDistribution:
            return "SRS Item Distribution"
        case .links:
            return "Links"
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .available:
            return 2
        case .upcomingReviews:
            return 3
        case .levelProgression:
            return 5
        case .srsDistribution:
            return 5
        case .links:
            return 2
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .available:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.numericDetailLarge.rawValue, for: indexPath) as! NumericDetailTableViewCell
                cell.availableColour = .globalTintColor
                cell.update(text: "Lessons", value: studyQueue?.lessonsAvailable)
                
                return cell
            case 1:
                let text = "Reviews"
                if let nextReviewTime = studyQueue?.nextReviewTime, case let .date(reviewDate) = nextReviewTime {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.reviewTime.rawValue, for: indexPath) as! ReviewTimeTableViewCell
                    cell.update(nextReviewDate: reviewDate)
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.numericDetailLarge.rawValue, for: indexPath) as! NumericDetailTableViewCell
                    cell.availableColour = .globalTintColor
                    cell.update(text: text, value: studyQueue?.reviewsAvailable)
                    
                    return cell
                }
            default: fatalError()
            }
        case .upcomingReviews:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.numericDetail.rawValue, for: indexPath) as! NumericDetailTableViewCell
                cell.update(text: "Within the Next Hour", value: studyQueue?.reviewsAvailableNextHour)
                
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.numericDetail.rawValue, for: indexPath) as! NumericDetailTableViewCell
                cell.update(text: "Within the Next Day", value: studyQueue?.reviewsAvailableNextDay)
                
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.reviewTimeline.rawValue, for: indexPath)
                
                return cell
            default: fatalError()
            }
        case .levelProgression:
            switch indexPath.row {
            case 0...1:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.levelProgression.rawValue, for: indexPath) as! LevelProgressTableViewCell
                cell.update(subjectType: indexPath.row == 0 ? .radical : .kanji, levelProgression: levelProgression)
                
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.durationDetail.rawValue, for: indexPath) as! DurationDetailTableViewCell
                cell.update(text: "Average Level Time", duration: levelTimeline?.stats?.mean)
                
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.durationDetail.rawValue, for: indexPath) as! DurationDetailTableViewCell
                cell.update(text: "Current Level Time", duration: (levelTimeline?.projectedCurrentLevel?.startDate.timeIntervalSinceNow).map { -$0 })
                
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.durationDetail.rawValue, for: indexPath) as! DurationDetailTableViewCell
                
                if let projectedCurrentLevel = levelTimeline?.projectedCurrentLevel {
                    let text = projectedCurrentLevel.isEndDateBasedOnLockedItem ? "Level Up In (Estimated)" : "Level Up In"
                    let startDate = projectedCurrentLevel.startDate
                    let endDateByProjection = projectedCurrentLevel.endDate
                    let expectedEndDate: Date
                    if projectedCurrentLevel.isEndDateBasedOnLockedItem {
                        let endDateByEstimate = startDate.addingTimeInterval(levelTimeline?.stats?.mean ?? 0)
                        expectedEndDate = max(endDateByEstimate, endDateByProjection)
                    } else {
                        expectedEndDate = endDateByProjection
                    }
                    
                    cell.update(text: text, duration: expectedEndDate.timeIntervalSinceNow)
                } else {
                    cell.update(text: "Level Up In", duration: nil)
                }
                
                return cell
            default: fatalError()
            }
        case .srsDistribution:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.srsProgress.rawValue, for: indexPath) as! SRSProgressTableViewCell
            switch indexPath.row {
            case 0:
                cell.update(srsStage: .apprentice, srsDistribution: srsDistribution)
            case 1:
                cell.update(srsStage: .guru, srsDistribution: srsDistribution)
            case 2:
                cell.update(srsStage: .master, srsDistribution: srsDistribution)
            case 3:
                cell.update(srsStage: .enlightened, srsDistribution: srsDistribution)
            case 4:
                cell.update(srsStage: .burned, srsDistribution: srsDistribution)
            default: fatalError()
            }
            
            return cell
        case .links:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.webLink.rawValue, for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = "WaniKani Dashboard"
            case 1:
                cell.textLabel!.text = "WaniKani Community Centre"
            default: fatalError()
            }
            
            return cell
        case .count:
            fatalError("This is a placeholder and not a real section")
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.header.rawValue) as! DashboardTableViewHeaderFooterView
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        view.titleLabel.text = title
        view.titleLabel.sizeToFit()
        let height = view.titleLabel.frame.height + view.layoutMargins.top + view.layoutMargins.bottom
        return height
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.header.rawValue) as! DashboardTableViewHeaderFooterView
        
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        view.titleLabel.text = title
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .available:
            switch indexPath.row {
            case 0:
                presentLessonsViewController()
                return nil
            case 1:
                presentReviewsViewController()
                return nil
            default: break
            }
        case .links:
            switch indexPath.row {
            case 0:
                let vc = WebViewController.wrapped(url: WaniKaniURL.dashboard)
                present(vc, animated: true, completion: nil)
                return nil
            case 1:
                let vc = WebViewController.wrapped(url: WaniKaniURL.communityCentre)
                present(vc, animated: true, completion: nil)
                return nil
            default: break
            }
        default: break
        }
        
        return indexPath
    }
    
    // MARK: - Timer
    
    private func makeUpdateTimer() -> Timer {
        let nextFireTime = Calendar.current.nextDate(after: Date(),
                                                     matching: DateComponents(second: 0, nanosecond: 0),
                                                     matchingPolicy: .nextTime)!
        if #available(iOS 10, *) {
            os_log("%@ update timer will fire at %@", type: .debug, String(describing: type(of: self)), nextFireTime as NSDate)
        }
        let timer = Timer(fireAt: nextFireTime, interval: .oneMinute, target: self, selector: #selector(updateUITimerDidFire(_:)), userInfo: nil, repeats: true)
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        
        return timer
    }
    
    @objc func updateUITimerDidFire(_ timer: Timer) {
        if #available(iOS 10, *) {
            os_log("%@ timer fire", type: .debug, String(describing: type(of: self)))
        }
        
        do {
            if try self.resourceRepository.hasStudyQueue() {
                self.studyQueue = try self.resourceRepository.studyQueue()
            }
            if try resourceRepository.hasLevelTimeline() {
                self.levelTimeline = try resourceRepository.levelTimeline()
            }
            
            self.tableView.reloadSections([TableViewSection.available.rawValue, TableViewSection.upcomingReviews.rawValue, TableViewSection.levelProgression.rawValue], with: .automatic)
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Failed to refresh study queue in timer callback: %@", type: .fault, error as NSError)
            }
            fatalError(error.localizedDescription)
        }
        
        guard !progressContainerView.isTrackedOperationInProgress else {
            return
        }
        
        let lastUpdate = resourceRepository.lastAppDataUpdateDate
        if let lastUpdate = lastUpdate, Date().timeIntervalSince(lastUpdate) < minimumFetchInterval {
            if #available(iOS 10, *) {
                os_log("No fetch required for update date %@ (%.3f < %.3f)", type: .debug, lastUpdate as NSDate, Date().timeIntervalSince(lastUpdate), minimumFetchInterval)
            }
            updateStatusBarForLastUpdate(lastUpdate)
            return
        }
        
        if #available(iOS 10, *) {
            os_log("Triggering fetch", type: .debug)
        }
        updateData(minimumFetchInterval: minimumFetchInterval, showAlertOnErrors: false)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(DashboardTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifier.header.rawValue)
        
        progressContainerView = ProgressReportingBarButtonItemView(frame: self.navigationController?.toolbar.frame ?? .zero)
        
        if #available(iOS 11.0, *) {
            let searchResultViewController = storyboard?.instantiateViewController(withIdentifier: "SubjectSearch") as! SubjectSearchTableViewController
            searchResultViewController.repositoryReader = resourceRepository
            
            let searchController = UISearchController(searchResultsController: searchResultViewController)
            searchController.searchResultsUpdater = searchResultViewController
            searchController.hidesNavigationBarDuringPresentation = false
            
            navigationItem.searchController = searchController
            
            definesPresentationContext = true
        }
        
        let barButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: progressContainerView),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        
        setToolbarItems(barButtonItems, animated: false)
        
        updateStatusBarForLastUpdate(resourceRepository.lastAppDataUpdateDate)
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            tableView.backgroundView = BlurredImageView(frame: tableView.frame, imageNamed: "Header", style: backgroundBlurEffectStyle)
        }
        
        do {
            if try resourceRepository.hasUserInformation() {
                self.userInformation = try resourceRepository.userInformation()
            }
            if try resourceRepository.hasStudyQueue() {
                self.studyQueue = try resourceRepository.studyQueue()
            }
            if try resourceRepository.hasLevelProgression() {
                self.levelProgression = try resourceRepository.levelProgression()
            }
            if try resourceRepository.hasSRSDistribution() {
                self.srsDistribution = try resourceRepository.srsDistribution()
            }
            if try resourceRepository.hasLevelTimeline() {
                self.levelTimeline = try resourceRepository.levelTimeline()
            }
        } catch {
            fatalError("Failed to load data from database: \(error)")
        }
        
        notificationObservers = addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateData(minimumFetchInterval: shouldForceDataReload ? 0 : minimumFetchInterval, showAlertOnErrors: false)
        updateUITimer = makeUpdateTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        updateUITimer?.invalidate()
        updateUITimer = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            return
        }
        
        if #available(iOS 10.0, *) {
            os_log("Preparing segue %@", type: .debug, identifier)
        }
        
        switch segueIdentifier {
        case .settings: break
        case .assignmentProgression:
            let vc = segue.destination as! AssignmentProgressionCollectionViewController
            let cell = sender as! LevelProgressTableViewCell
            vc.repositoryReader = resourceRepository
            vc.subjectType = cell.subjectType
        case .reviewTimeline:
            let vc = segue.destination as! ReviewTimelineTableViewController
            vc.repositoryReader = resourceRepository
        case .srsProgressDetail:
            let vc = segue.destination as! SubjectCollectionViewController
            let cell = sender as! SRSProgressTableViewCell
            vc.repositoryReader = resourceRepository
            vc.srsStage = cell.srsStage
        }
    }
    
    // MARK: - Update UI
    
    private func updateStatusBarForLastUpdate(_ lastUpdate: Date?) {
        guard let lastUpdate = lastUpdate else {
            progressContainerView.textLabel.text = "No data found: fetch required"
            return
        }
        
        switch Date().timeIntervalSince(lastUpdate) {
        case let interval where interval < 2 * .oneMinute:
            progressContainerView.textLabel.text = "Updated Just Now"
        case let interval where interval < 6 * .oneMinute:
            let relativeDate = lastUpdateDateRelativeFormatter.string(from: interval)!
            progressContainerView.textLabel.text = "Updated \(relativeDate) ago"
        default:
            if Calendar.current.isDateInToday(lastUpdate) {
                let formatter = lastUpdateDateAbsoluteFormatter
                formatter.dateStyle = .none
                let formatted = formatter.string(from: lastUpdate)
                progressContainerView.textLabel.text = "Updated at \(formatted)"
            } else {
                let formatter = lastUpdateDateAbsoluteFormatter
                formatter.dateStyle = .medium
                let formatted = formatter.string(from: lastUpdate)
                progressContainerView.textLabel.text = "Updated: \(formatted)"
            }
        }
    }
    
    private func updateData(minimumFetchInterval: TimeInterval, showAlertOnErrors: Bool) {
        shouldForceDataReload = false
        let progress = resourceRepository.updateAppData(minimumFetchInterval: minimumFetchInterval) { result in
            DispatchQueue.main.async {
                if let refreshControl = self.refreshControl, refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
                self.progressContainerView.markComplete()
                self.updateStatusBarForLastUpdate(self.resourceRepository.lastAppDataUpdateDate)
                
                switch result {
                case .success:
                    self.tableView.reloadData()
                case .noData:
                    break
                case let .error(error):
                    if showAlertOnErrors {
                        self.showAlert(title: "Failed to update data", message: error.localizedDescription)
                    }
                }
            }
        }
        
        progressContainerView.track(progress: progress, description: "Downloading data from WaniKani...")
    }
    
    private func addNotificationObservers() -> [NSObjectProtocol] {
        if #available(iOS 10.0, *) {
            os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        }
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [unowned self] _ in
                do {
                    if try self.resourceRepository.hasUserInformation() {
                        self.userInformation = try self.resourceRepository.userInformation()
                    }
                    if try self.resourceRepository.hasLevelProgression() {
                        self.levelProgression = try self.resourceRepository.levelProgression()
                    }
                    if try self.resourceRepository.hasLevelTimeline() {
                        self.levelTimeline = try self.resourceRepository.levelTimeline()
                    }
                } catch {
                    if #available(iOS 10.0, *) {
                        os_log("Failed to refresh data in notification observer: %@", type: .fault, error as NSError)
                    }
                    fatalError(error.localizedDescription)
                }
                
                self.tableView.reloadSections([TableViewSection.levelProgression.rawValue], with: .automatic)
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [unowned self] _ in
                do {
                    if try self.resourceRepository.hasStudyQueue() {
                        self.studyQueue = try self.resourceRepository.studyQueue()
                    }
                    if try self.resourceRepository.hasLevelProgression() {
                        self.levelProgression = try self.resourceRepository.levelProgression()
                    }
                    if try self.resourceRepository.hasSRSDistribution() {
                        self.srsDistribution = try self.resourceRepository.srsDistribution()
                    }
                    if try self.resourceRepository.hasLevelTimeline() {
                        self.levelTimeline = try self.resourceRepository.levelTimeline()
                    }
                } catch {
                    if #available(iOS 10.0, *) {
                        os_log("Failed to refresh data in notification observer: %@", type: .fault, error as NSError)
                    }
                    fatalError(error.localizedDescription)
                }
                
                let sectionsToReload: IndexSet = [TableViewSection.available.rawValue, TableViewSection.upcomingReviews.rawValue,
                                                  TableViewSection.levelProgression.rawValue, TableViewSection.srsDistribution.rawValue]
                self.tableView.reloadSections(sectionsToReload, with: .automatic)
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [unowned self] _ in
                do {
                    if try self.resourceRepository.hasLevelProgression() {
                        self.levelProgression = try self.resourceRepository.levelProgression()
                    }
                    if try self.resourceRepository.hasLevelTimeline() {
                        self.levelTimeline = try self.resourceRepository.levelTimeline()
                    }
                } catch {
                    if #available(iOS 10.0, *) {
                        os_log("Failed to refresh data in notification observer: %@", type: .fault, error as NSError)
                    }
                    fatalError(error.localizedDescription)
                }
                
                let sectionsToReload: IndexSet = [TableViewSection.available.rawValue, TableViewSection.upcomingReviews.rawValue,
                                                  TableViewSection.levelProgression.rawValue, TableViewSection.srsDistribution.rawValue]
                self.tableView.reloadSections(sectionsToReload, with: .automatic)
            },
            NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { [unowned self] _ in
                self.updateData(minimumFetchInterval: 5 * .oneMinute, showAlertOnErrors: false)
            }
        ]
        
        return notificationObservers
    }
    
}

// MARK: - WebViewControllerDelegate
extension DashboardTableViewController: WebViewControllerDelegate {
    func webViewController(_ controller: WebViewController, didFinish url: URL?) {
        guard let url = url else {
            return
        }
        
        switch url {
        case WaniKaniURL.lessonHome, WaniKaniURL.lessonSession, WaniKaniURL.reviewHome, WaniKaniURL.reviewSession:
            shouldForceDataReload = true
        default: break
        }
    }
}
