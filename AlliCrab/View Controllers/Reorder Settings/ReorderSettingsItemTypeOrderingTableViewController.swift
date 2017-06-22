//
//  ReorderSettingsItemTypeOrderingTableViewController.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReorderSettingsItemTypeOrderingTableViewControllerDelegate: class {
    func reorderSettingsItemTypeOrderChanged(to: [ReorderSettings.ItemType])
}

class ReorderSettingsItemTypeOrderingTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: ReorderSettingsItemTypeOrderingTableViewControllerDelegate?
    
    var values: [ReorderSettings.ItemType] = [] {
        didSet {
            delegate?.reorderSettingsItemTypeOrderChanged(to: values)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func reverse(_ sender: UIBarButtonItem) {
        values.reverse()
        tableView.reloadData()
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setEditing(true, animated: false)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let valueForRow = values[indexPath.row]
        
        switch valueForRow {
        case .radical:
            cell.textLabel!.text = "Radicals"
        case .kanji:
            cell.textLabel!.text = "Kanji"
        case .vocabulary:
            cell.textLabel!.text = "Vocabulary"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let value = values[fromIndexPath.row]
        
        // Create a local copy of values so we can move value within the array atomically
        var newValues = values
        newValues.remove(at: fromIndexPath.row)
        newValues.insert(value, at: to.row)
        
        values = newValues
    }
    
}
