//
//  SRSDataItemCollectionViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

private let headerReuseIdentifier = "Header"
private let radicalReuseIdentifier = "RadicalDataItemCell"
private let kanjiReuseIdentifier = "KanjiDataItemCell"

private struct ClassifiedSRSDataItems {
    let pending: [SRSDataItem]?
    let complete: [SRSDataItem]?
    
    init(items: [SRSDataItem]) {
        let items = items.sort { $0.userSpecificSRSData?.srsLevelNumeric < $1.userSpecificSRSData?.srsLevelNumeric }
        pending = items.filter(self.dynamicType.isPending)
        complete = items.filter(self.dynamicType.isComplete)
    }
    
    private static func isPending(item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return true }
        return srsLevel < SRSLevel.Guru.numericLevelThreshold
    }
    
    private static func isComplete(item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return false }
        return srsLevel >= SRSLevel.Guru.numericLevelThreshold
    }
}

class SRSDataItemCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private enum CollectionViewSections: Int {
        case Pending = 0, Complete = 1
    }
    
    // MARK: - Properties
    
    private var classifiedItems: ClassifiedSRSDataItems?
    func setSRSDataItems(items: [SRSDataItem], withTitle title: String) {
        classifiedItems = ClassifiedSRSDataItems(items: items)
        navigationItem.title = title
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collectionViewSection = CollectionViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch collectionViewSection {
        case .Pending: return classifiedItems?.pending?.count ?? 0
        case .Complete: return classifiedItems?.complete?.count ?? 0
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let collectionViewSection = CollectionViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        if let items = classifiedItems {
            let item: SRSDataItem
            switch collectionViewSection {
            case .Pending: item = items.pending![indexPath.row]
            case .Complete: item = items.complete![indexPath.row]
            }
            
            switch item {
            case let radical as Radical:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(radicalReuseIdentifier, forIndexPath: indexPath) as! RadicalGuruProgressCollectionViewCell
                cell.radical = radical
                return cell
            case let kanji as Kanji:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kanjiReuseIdentifier, forIndexPath: indexPath) as! KanjiGuruProgressCollectionViewCell
                cell.kanji = kanji
                return cell
            default: fatalError("Only Radicals and Kanji are supported by \(self.dynamicType)")
            }
        } else {
            fatalError("Neither kanji or radicals set, yet it tried to dequeue a cell")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        guard let collectionViewSection = CollectionViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: headerReuseIdentifier, forIndexPath: indexPath) as! SRSItemHeaderCollectionReusableView
        
        if kind == UICollectionElementKindSectionHeader && self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) > 0 {
            switch collectionViewSection {
            case .Pending: view.headerLabel.text = "Remaining to Level"
            case .Complete: view.headerLabel.text = "Complete"
            }
            view.hidden = false
        } else {
            view.headerLabel.text = nil
            view.hidden = true
        }
        
        return view
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // MARK: - UICollectionViewDelegate
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return false
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
}
