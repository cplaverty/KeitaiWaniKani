//
//  ReorderSettingsTableViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit

protocol ReorderSettingsTableViewControllerDelegate: class {
    func reorderSettingsTableViewControllerDidFinish(_ controller: ReorderSettingsTableViewController)
}

class ReorderSettingsTableViewController: UITableViewController {
    
    private enum TableViewSections: Int {
        case basicSettings = 0, sortTypes, sortLevels, sortOrder
    }
    
    // MARK: - Properties
    
    var settings: ReorderSettings = ReorderSettings()
    
    weak var delegate: ReorderSettingsTableViewControllerDelegate?
    
    // MARK: - Outlets
    
    @IBOutlet weak var oneByOneSwitch: UISwitch!
    @IBOutlet weak var quizOrderCell: UITableViewCell!
    @IBOutlet weak var sortByTypeSwitch: UISwitch!
    @IBOutlet weak var typeOrderCell: UITableViewCell!
    @IBOutlet weak var sortByLevelSwitch: UISwitch!
    @IBOutlet weak var levelOrderCell: UITableViewCell!
    @IBOutlet weak var sortOrderCell: UITableViewCell!
    
    // MARK: - Actions
    
    @IBAction func reorder(sender: UIBarButtonItem) {
        delegate?.reorderSettingsTableViewControllerDidFinish(self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case oneByOneSwitch:
            settings.oneByOne = sender.isOn
        case sortByTypeSwitch:
            settings.sortTypes = sender.isOn
        case sortByLevelSwitch:
            settings.sortLevels = sender.isOn
        default: fatalError("Unexpected switch in switchValueChanged event!")
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    // MARK: - Update UI
    
    func updateUI() {
        oneByOneSwitch.isOn = settings.oneByOne
        
        switch settings.questionTypeMode {
        case .random:
            quizOrderCell.detailTextLabel!.text = "Random"
        case .readingHeavy:
            quizOrderCell.detailTextLabel!.text = "Reading, Meaning"
        case .meaningHeavy:
            quizOrderCell.detailTextLabel!.text = "Meaning, Reading"
        }
        
        sortByTypeSwitch.isOn = settings.sortTypes
        typeOrderCell.detailTextLabel!.text = settings.itemPriority.lazy.map { $0.rawValue.capitalized }.joined(separator: ", ")
        
        sortByLevelSwitch.isOn = settings.sortLevels
        levelOrderCell.detailTextLabel!.text = settings.levelPriority.lazy.map { String($0) }.joined(separator: ", ")
        
        switch settings.typePriorityMode {
        case .random:
            sortOrderCell.detailTextLabel!.text = "Random"
        case .levelHeavy:
            sortOrderCell.detailTextLabel!.text = "Level, Type"
        case .typeHeavy:
            sortOrderCell.detailTextLabel!.text = "Type, Level"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "ItemOrdering":
            let vc = segue.destinationContentViewController as! ReorderSettingsItemOrderingTableViewController
            vc.selectedValue = settings.questionTypeMode
            vc.delegate = self
        case "ItemTypeOrdering":
            let vc = segue.destinationContentViewController as! ReorderSettingsItemTypeOrderingTableViewController
            vc.values = settings.itemPriority
            vc.delegate = self
        case "LevelOrdering":
            let vc = segue.destinationContentViewController as! ReorderSettingsLevelOrderingTableViewController
            vc.values = settings.levelPriority
            vc.delegate = self
        case "SortingPriority":
            let vc = segue.destinationContentViewController as! ReorderSettingsSortingPriorityTableViewController
            vc.selectedValue = settings.typePriorityMode
            vc.delegate = self
        default: break
        }
    }
}

// MARK: - ReorderSettingsItemOrderingTableViewControllerDelegate

extension ReorderSettingsTableViewController: ReorderSettingsItemOrderingTableViewControllerDelegate {
    func reorderSettingsQuestionTypeModeChanged(to newValue: ReorderSettings.QuestionTypeMode) {
        settings.questionTypeMode = newValue
    }
}

// MARK: - ReorderSettingsItemTypeOrderingTableViewControllerDelegate

extension ReorderSettingsTableViewController: ReorderSettingsItemTypeOrderingTableViewControllerDelegate {
    func reorderSettingsItemTypeOrderChanged(to newValue: [ReorderSettings.ItemType]) {
        settings.itemPriority = newValue
    }
}

// MARK: - ReorderSettingsLevelOrderingTableViewControllerDelegate

extension ReorderSettingsTableViewController: ReorderSettingsLevelOrderingTableViewControllerDelegate {
    func reorderSettingsLevelOrderChanged(to newValue: [Int]) {
        settings.levelPriority = newValue
    }
}

// MARK: - ReorderSettingsSortingPriorityTableViewControllerDelegate

extension ReorderSettingsTableViewController: ReorderSettingsSortingPriorityTableViewControllerDelegate {
    func reorderSettingsTypePriorityModeChanged(to newValue: ReorderSettings.TypePriorityMode) {
        settings.typePriorityMode = newValue
    }
}
