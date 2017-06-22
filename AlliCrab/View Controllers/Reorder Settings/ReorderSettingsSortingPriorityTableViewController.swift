//
//  ReorderSettingsSortingPriorityTableViewController.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReorderSettingsSortingPriorityTableViewControllerDelegate: class {
    func reorderSettingsTypePriorityModeChanged(to: ReorderSettings.TypePriorityMode)
}

private let values: [ReorderSettings.TypePriorityMode] = [.random, .levelHeavy, .typeHeavy]

class ReorderSettingsSortingPriorityTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: ReorderSettingsSortingPriorityTableViewControllerDelegate?
    
    var selectedValue: ReorderSettings.TypePriorityMode? {
        didSet {
            if let selectedValue = selectedValue {
                delegate?.reorderSettingsTypePriorityModeChanged(to: selectedValue)
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
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let valueForRow = values[indexPath.row]
        
        switch valueForRow {
        case .random:
            cell.textLabel!.text = "Random"
        case .levelHeavy:
            cell.textLabel!.text = "Level, then type"
        case .typeHeavy:
            cell.textLabel!.text = "Type, then level"
        }
        cell.accessoryType = valueForRow == selectedValue ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
}
