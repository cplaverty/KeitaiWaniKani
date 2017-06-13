//
//  ReorderSettingsLevelOrderingTableViewController.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReorderSettingsLevelOrderingTableViewControllerDelegate: class {
    func reorderSettingsLevelOrderChanged(to: [Int])
}

class ReorderSettingsLevelOrderingTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: ReorderSettingsLevelOrderingTableViewControllerDelegate?
    
    var values: [Int] = [] {
        didSet {
            delegate?.reorderSettingsLevelOrderChanged(to: values)
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
        return isEditing ? .delete : .none
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
        let valueForRow = values[indexPath.row]
        
        cell.textLabel!.text = String(describing: valueForRow)
        
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            values.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
}
