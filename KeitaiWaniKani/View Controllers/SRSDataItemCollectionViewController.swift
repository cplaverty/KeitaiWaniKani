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
    struct Section {
        let title: String
        let items: [SRSDataItem]
    }
    
    let sections: [Section]
    
    init(items: [SRSDataItem]) {
        let items = items.sort(SRSDataItemSorting.byProgress)
        var sections: [Section] = []
        sections.reserveCapacity(2)
        
        let pending = items.filter(self.dynamicType.isPending)
        if !pending.isEmpty {
            sections.append(Section(title: "Remaining to Level", items: pending))
        }
        
        let complete = items.filter(self.dynamicType.isComplete)
        if !complete.isEmpty {
            sections.append(Section(title: "Complete", items: complete))
        }
        
        self.sections = sections
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

class SRSDataItemCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, WKWebViewControllerDelegate {
    
    // MARK: - Properties
    
    private var classifiedItems: ClassifiedSRSDataItems?
    func setSRSDataItems(items: [SRSDataItem], withTitle title: String) {
        classifiedItems = ClassifiedSRSDataItems(items: items)
        navigationItem.title = title
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        return classifiedItems.sections.count
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        
        return classifiedItems.sections[section].items.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let classifiedItems = classifiedItems {
            let item = classifiedItems.sections[indexPath.section].items[indexPath.row]
            
            switch item {
            case let radical as Radical:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(radicalReuseIdentifier, forIndexPath: indexPath) as! RadicalGuruProgressCollectionViewCell
                cell.dataItem = radical
                return cell
            case let kanji as Kanji:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kanjiReuseIdentifier, forIndexPath: indexPath) as! KanjiGuruProgressCollectionViewCell
                cell.dataItem = kanji
                return cell
            default: fatalError("Only Radicals and Kanji are supported by \(self.dynamicType)")
            }
        } else {
            fatalError("Neither kanji or radicals set, yet it tried to dequeue a cell")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: headerReuseIdentifier, forIndexPath: indexPath) as! SRSItemHeaderCollectionReusableView
        
        if kind == UICollectionElementKindSectionHeader {
            let section = classifiedItems?.sections[indexPath.section]
            view.headerLabel.text = section?.title
        } else {
            view.headerLabel.text = nil
        }
        
        return view
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SRSDataItemInfoURL, let url = cell.srsDataItemInfoURL else { return }
        
        self.presentViewController(WKWebViewController.forURL(url) { $0.delegate = self }, animated: true, completion: nil)
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(controller: WKWebViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        
        let backgroundView = UIView(frame: collectionView!.frame)
        backgroundView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        let imageView = UIImageView(image: UIImage(named: "Header"))
        imageView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        imageView.contentMode = .ScaleAspectFill
        imageView.frame = backgroundView.frame
        backgroundView.addSubview(imageView)
        let visualEffectBlurView = UIVisualEffectView(effect: blurEffect)
        visualEffectBlurView.frame = imageView.frame
        visualEffectBlurView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        backgroundView.addSubview(visualEffectBlurView)
        let darkenView = UIView(frame: visualEffectBlurView.frame)
        darkenView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        darkenView.alpha = 0.1
        darkenView.backgroundColor = ApplicationSettings.globalTintColor()
        visualEffectBlurView.contentView.addSubview(darkenView)
        collectionView!.backgroundView = backgroundView
    }
}
