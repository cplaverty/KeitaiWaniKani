//
//  ReorderSettingsItemOrderingTableViewController.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReorderSettingsItemOrderingTableViewControllerDelegate: class {
    func reorderSettingsQuestionTypeModeChanged(to: ReorderSettings.QuestionTypeMode)
}

private let values: [ReorderSettings.QuestionTypeMode] = [.random, .meaningHeavy, .readingHeavy]

class ReorderSettingsItemOrderingTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: ReorderSettingsItemOrderingTableViewControllerDelegate?
    
    var selectedValue: ReorderSettings.QuestionTypeMode? {
        didSet {
            if let selectedValue = selectedValue {
                delegate?.reorderSettingsQuestionTypeModeChanged(to: selectedValue)
            }
        }
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? "The order in which you will be questioned on each item" : nil
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let valueForRow = values[indexPath.row]
        
        switch valueForRow {
        case .random:
            cell.textLabel!.text = "Random"
        case .meaningHeavy:
            cell.textLabel!.text = "Meaning, then reading"
        case .readingHeavy:
            cell.textLabel!.text = "Reading, then meaning"
        }
        cell.accessoryType = valueForRow == selectedValue ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
}
