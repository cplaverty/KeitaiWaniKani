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
    }
    
    private enum TableViewSection: Int, CaseIterable {
        case available = 0, upcomingReviews, levelProgression, srsDistribution, links
    }
    
    // MARK: - Properties
    
    private let foregroundFetchInterval = 5 * .oneMinute
    private let backgroundFetchInterval = 15 * .oneMinute
    
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
    var lastError: Error?
    
    private let backgroundBlurEffectStyle = UIBlurEffect.Style.extraLight
    
    private var userInformation: UserInformation?
    private var studyQueue: StudyQueue?
    private var levelProgression: CurrentLevelProgression?
    private var srsDistribution: SRSDistribution?
    private var levelTimeline: LevelData?
    
    private var updateUITimer: Timer?
    private var notificationObservers: [NSObjectProtocol]?
    private var progressContainerView: ProgressReportingBarButtonItemView!
    
    // MARK: - Initialisers
    
    deinit {
        updateUITimer?.invalidate()
        if let notificationObservers = notificationObservers {
            os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
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
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func presentReviewsViewController() {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: WaniKaniURL.reviewSession) { controller in
            controller.delegate = self
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func presentSettingsViewController() {
        performSegue(withIdentifier: SegueIdentifier.settings.rawValue, sender: nil)
    }
    
    @IBAction func showLastError() {
        guard let lastError = self.lastError else { return }
        
        showAlert(title: "Failed to update data", message: lastError.localizedDescription)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.allCases.count
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
            if let level = userInformation?.effectiveLevel {
                return "Level \(level) Progress"
            } else {
                return "Level Progress"
            }
        case .srsDistribution:
            return "SRS Item Distribution"
        case .links:
            return "Links"
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
            if let projectedCurrentLevel = levelTimeline?.projectedCurrentLevel, case .actual = projectedCurrentLevel.endDateMethodology {
                return 4
            } else {
                return 5
            }
        case .srsDistribution:
            return 5
        case .links:
            return 2
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
                if let projectedCurrentLevel = levelTimeline?.projectedCurrentLevel, case .actual = projectedCurrentLevel.endDateMethodology {
                    cell.update(text: "Level Passed In", duration: projectedCurrentLevel.endDate.timeIntervalSince(projectedCurrentLevel.startDate))
                } else {
                    cell.update(text: "Current Level Time", duration: (levelTimeline?.projectedCurrentLevel?.startDate.timeIntervalSinceNow).map({ -$0 }))
                }
                
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.durationDetail.rawValue, for: indexPath) as! DurationDetailTableViewCell
                
                if let projectedCurrentLevel = levelTimeline?.projectedCurrentLevel {
                    let text: String
                    let expectedEndDate: Date
                    switch projectedCurrentLevel.endDateMethodology {
                    case .calculated(usingLockedItem: true):
                        let endDateByEstimate = projectedCurrentLevel.startDate.addingTimeInterval(levelTimeline?.stats?.mean ?? 0)
                        expectedEndDate = max(projectedCurrentLevel.endDate, endDateByEstimate)
                        text = "Level Up In (Estimated)"
                    case .calculated(usingLockedItem: false):
                        text = "Level Up In"
                        expectedEndDate = projectedCurrentLevel.endDate
                    case .actual:
                        fatalError()
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
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.header.rawValue) as! DashboardTableViewHeaderFooterView
        let title = self.tableView(tableView, titleForHeaderInSection: section)
        view.titleLabel.text = title
        
        let height = view.contentView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
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
                presentSafariViewController(url: WaniKaniURL.dashboard)
                return nil
            case 1:
                presentSafariViewController(url: WaniKaniURL.communityCentre)
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
        os_log("%@ update timer will fire at %@", type: .debug, String(describing: type(of: self)), nextFireTime as NSDate)
        let timer = Timer(fireAt: nextFireTime, interval: .oneMinute, target: self, selector: #selector(updateUITimerDidFire(_:)), userInfo: nil, repeats: true)
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .default)
        
        return timer
    }
    
    @objc func updateUITimerDidFire(_ timer: Timer) {
        os_log("%@ timer fire", type: .debug, String(describing: type(of: self)))
        
        do {
            if try self.resourceRepository.hasStudyQueue() {
                self.studyQueue = try self.resourceRepository.studyQueue()
            }
            if try resourceRepository.hasLevelTimeline() {
                self.levelTimeline = try resourceRepository.levelTimeline()
            }
            
            self.tableView.reloadSections([TableViewSection.available.rawValue, TableViewSection.upcomingReviews.rawValue, TableViewSection.levelProgression.rawValue], with: .automatic)
        } catch {
            os_log("Failed to refresh study queue in timer callback: %@", type: .fault, error as NSError)
            fatalError(error.localizedDescription)
        }
        
        guard !progressContainerView.isTrackedOperationInProgress else {
            return
        }
        
        let lastUpdate = resourceRepository.lastAppDataUpdateDate
        if let lastUpdate = lastUpdate, Date().timeIntervalSince(lastUpdate) < backgroundFetchInterval {
            os_log("No fetch required for update date %@ (%.3f < %.3f)", type: .debug, lastUpdate as NSDate, Date().timeIntervalSince(lastUpdate), backgroundFetchInterval)
            updateStatusBarForLastUpdate(lastUpdate)
            return
        }
        
        os_log("Triggering fetch", type: .debug)
        updateData(minimumFetchInterval: backgroundFetchInterval, showAlertOnErrors: false)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(DashboardTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifier.header.rawValue)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showLastError))
        let toolbarBounds = CGRect(origin: .zero, size: self.navigationController?.toolbar.frame.size ?? .zero)
        progressContainerView = ProgressReportingBarButtonItemView(frame: toolbarBounds)
        progressContainerView.textLabel.addGestureRecognizer(tapGestureRecognizer)
        progressContainerView.textLabel.isUserInteractionEnabled = true
        
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
        
        if !UIAccessibility.isReduceTransparencyEnabled {
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
        
        updateData(minimumFetchInterval: foregroundFetchInterval, showAlertOnErrors: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        os_log("Preparing segue %@", type: .debug, identifier)
        
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
        }
    }
    
    // MARK: - Update UI
    
    private func updateStatusBarForLastUpdate(_ lastUpdate: Date?) {
        let formattedUpdateTime: String
        if let lastUpdate = lastUpdate {
            switch Date().timeIntervalSince(lastUpdate) {
            case let interval where interval < 2 * .oneMinute:
                formattedUpdateTime = "Updated Just Now"
            case let interval where interval < 6 * .oneMinute:
                let relativeDate = lastUpdateDateRelativeFormatter.string(from: interval)!
                formattedUpdateTime = "Updated \(relativeDate) ago"
            default:
                if Calendar.current.isDateInToday(lastUpdate) {
                    let formatter = lastUpdateDateAbsoluteFormatter
                    formatter.dateStyle = .none
                    let formatted = formatter.string(from: lastUpdate)
                    formattedUpdateTime = "Updated at \(formatted)"
                } else {
                    let formatter = lastUpdateDateAbsoluteFormatter
                    formatter.dateStyle = .medium
                    let formatted = formatter.string(from: lastUpdate)
                    formattedUpdateTime = "Updated: \(formatted)"
                }
            }
        } else {
            formattedUpdateTime = "No data found: fetch required"
            return
        }
        
        if lastError != nil {
            let text = NSMutableAttributedString(string: formattedUpdateTime + "\n")
            text.append(NSAttributedString(string: "Error when fetching ", attributes: [.foregroundColor: UIColor.gray]))
            text.append(NSAttributedString(string: "Details...", attributes: [.foregroundColor: UIColor.globalTintColor]))
            progressContainerView.textLabel.attributedText = text
        } else {
            progressContainerView.textLabel.text = formattedUpdateTime
        }
    }
    
    private func updateData(minimumFetchInterval: TimeInterval, showAlertOnErrors: Bool) {
        let progress = resourceRepository.updateAppData(minimumFetchInterval: minimumFetchInterval) { result in
            DispatchQueue.main.async {
                if let refreshControl = self.refreshControl, refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
                
                switch result {
                case .success:
                    self.lastError = nil
                    self.tableView.reloadData()
                case .noData:
                    self.lastError = nil
                    break
                case .error(WaniKaniAPIError.invalidAPIKey):
                    os_log("Logging out due to invalid API key")
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    // This will pop to home screen
                    delegate.logOut()
                    
                    UIApplication.shared.keyWindow?.rootViewController?.showAlert(title: "Invalid API Key", message: "You have been logged out because WaniKani has reported that your API key is now invalid.  Please log in again.")
                    return
                case let .error(error):
                    self.lastError = error
                    if showAlertOnErrors {
                        self.showAlert(title: "Failed to update data", message: error.localizedDescription)
                    }
                }
                
                self.progressContainerView.markComplete()
                self.updateStatusBarForLastUpdate(self.resourceRepository.lastAppDataUpdateDate)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if progress.completedUnitCount < progress.totalUnitCount && !progress.isCancelled {
                self.progressContainerView.track(progress: progress, description: "Downloading data from WaniKani...")
            }
        }
    }
    
    private func addNotificationObservers() -> [NSObjectProtocol] {
        os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.updateUI()
            },
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self = self else { return }
                
                self.updateData(minimumFetchInterval: self.foregroundFetchInterval, showAlertOnErrors: false)
            }
        ]
        
        return notificationObservers
    }
    
    private func updateUI() {
        do {
            if try self.resourceRepository.hasUserInformation() {
                self.userInformation = try self.resourceRepository.userInformation()
            }
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
            os_log("Failed to refresh data in notification observer: %@", type: .fault, error as NSError)
            fatalError(error.localizedDescription)
        }
        
        let sectionsToReload: IndexSet = [TableViewSection.available.rawValue, TableViewSection.upcomingReviews.rawValue,
                                          TableViewSection.levelProgression.rawValue, TableViewSection.srsDistribution.rawValue]
        self.tableView.reloadSections(sectionsToReload, with: .automatic)
    }
    
}

// MARK: - WebViewControllerDelegate
extension DashboardTableViewController: WebViewControllerDelegate {
    func webViewControllerDidFinish(_ controller: WebViewController) {
        updateData(minimumFetchInterval: 0, showAlertOnErrors: false)
    }
}
