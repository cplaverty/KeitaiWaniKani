//
//  ReviewTimelineFilterTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReviewTimelineFilterDelegate: class {
    func reviewTimelineFilter(didChangeTo: ReviewTimelineFilter)
}

class ReviewTimelineFilterTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case basic = "Basic"
    }
    
    // MARK: - Properties
    
    weak var delegate: ReviewTimelineFilterDelegate?
    
    var selectedValue: ReviewTimelineFilter? {
        didSet {
            if let selectedValue = selectedValue {
                delegate?.reviewTimelineFilter(didChangeTo: selectedValue)
            }
        }
    }
    
    private let values: [ReviewTimelineFilter] = [.none, .currentLevel, .toBeBurned]
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
        let valueForRow = values[indexPath.row]
        
        switch valueForRow {
        case .none:
            cell.textLabel!.text = "All Reviews"
        case .currentLevel:
            cell.textLabel!.text = "Current Level Reviews"
        case .toBeBurned:
            cell.textLabel!.text = "Burn Reviews"
        }
        cell.accessoryType = valueForRow == selectedValue ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let previousSelection = selectedValue.map { IndexPath(row: values.index(of: $0)!, section: 0) }
        selectedValue = values[indexPath.row]
        
        if let previousSelection = previousSelection {
            tableView.reloadRows(at: [previousSelection, indexPath], with: .automatic)
        } else {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        return nil
    }
    
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ReviewTimelineFilterTableViewController: UIPopoverPresentationControllerDelegate {
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if style == .popover || style == .none {
            return nil
        }
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
}
