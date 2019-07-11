//
//  ReviewTimelineFilterTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReviewTimelineOptionsDelegate: class {
    func reviewTimelineFilter(didChangeTo: ReviewTimelineFilter)
    func reviewTimelineCountMethod(didChangeTo: ReviewTimelineCountMethod)
}

class ReviewTimelineOptionsTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case basic = "Basic"
    }
    
    private enum TableViewSection: Int, CaseIterable {
        case filter = 0, countMethod
    }
    
    // MARK: - Properties
    
    weak var delegate: ReviewTimelineOptionsDelegate?
    
    var selectedFilterValue: ReviewTimelineFilter = ApplicationSettings.reviewTimelineFilterType
    var selectedCountMethodValue: ReviewTimelineCountMethod = ApplicationSettings.reviewTimelineValueType
    
    private var filterValues: [ReviewTimelineFilter] { return ReviewTimelineFilter.allCases }
    private var countMethodValues: [ReviewTimelineCountMethod] { return ReviewTimelineCountMethod.allCases }
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
        
        switch tableViewSection {
        case .filter:
            let valueForRow = filterValues[indexPath.row]
            switch valueForRow {
            case .none:
                cell.textLabel!.text = "All Reviews"
            case .currentLevel:
                cell.textLabel!.text = "Current Level Reviews"
            case .toBeBurned:
                cell.textLabel!.text = "Burn Reviews"
            }
            cell.accessoryType = valueForRow == selectedFilterValue ? .checkmark : .none
        case .countMethod:
            let valueForRow = countMethodValues[indexPath.row]
            switch valueForRow {
            case .histogram:
                cell.textLabel!.text = "Count"
            case .cumulative:
                cell.textLabel!.text = "Cumulative Total"
            }
            cell.accessoryType = valueForRow == selectedCountMethodValue ? .checkmark : .none
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .filter: return filterValues.count
        case .countMethod: return countMethodValues.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .filter: return "Filter"
        case .countMethod: return "Values"
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        let previousSelection: IndexPath?
        switch tableViewSection {
        case .filter:
            previousSelection = IndexPath(row: filterValues.firstIndex(of: ApplicationSettings.reviewTimelineFilterType)!, section: indexPath.section)
            selectedFilterValue = filterValues[indexPath.row]
            if ApplicationSettings.reviewTimelineFilterType != selectedFilterValue {
                ApplicationSettings.reviewTimelineFilterType = selectedFilterValue
                delegate?.reviewTimelineFilter(didChangeTo: selectedFilterValue)
            }
        case .countMethod:
            previousSelection = IndexPath(row: countMethodValues.firstIndex(of: ApplicationSettings.reviewTimelineValueType)!, section: indexPath.section)
            selectedCountMethodValue = countMethodValues[indexPath.row]
            if ApplicationSettings.reviewTimelineValueType != selectedCountMethodValue {
                ApplicationSettings.reviewTimelineValueType = selectedCountMethodValue
                delegate?.reviewTimelineCountMethod(didChangeTo: selectedCountMethodValue)
            }
        }
        
        if let previousSelection = previousSelection {
            tableView.reloadRows(at: [previousSelection, indexPath], with: .automatic)
        } else {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ReviewTimelineOptionsTableViewController: UIPopoverPresentationControllerDelegate {
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if style == .popover || style == .none {
            return nil
        }
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
}
