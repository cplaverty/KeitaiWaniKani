//
//  SRSDataItemCollectionViewController.swift
//  AlliCrab
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
        let items = items.sorted(by: SRSDataItemSorting.byProgress)
        var sections: [Section] = []
        sections.reserveCapacity(2)
        
        let pending = items.filter(type(of: self).isPending)
        if !pending.isEmpty {
            sections.append(Section(title: "Remaining to Level", items: pending))
        }
        
        let complete = items.filter(type(of: self).isComplete)
        if !complete.isEmpty {
            sections.append(Section(title: "Complete", items: complete))
        }
        
        self.sections = sections
    }
    
    private static func isPending(_ item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return true }
        return srsLevel < SRSLevel.guru.numericLevelThreshold
    }
    
    private static func isComplete(_ item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return false }
        return srsLevel >= SRSLevel.guru.numericLevelThreshold
    }
}

class SRSDataItemCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, WKWebViewControllerDelegate {
    
    // MARK: - Properties
    
    private var classifiedItems: ClassifiedSRSDataItems?
    func setSRSDataItems(_ items: [SRSDataItem], withTitle title: String) {
        classifiedItems = ClassifiedSRSDataItems(items: items)
        navigationItem.title = title
    }
    
    private var headerFont: UIFont {
        if #available(iOS 9.0, *) {
            return UIFont.preferredFont(forTextStyle: .title1)
        } else {
            let headlineFont = UIFont.preferredFont(forTextStyle: .body)
            let pointSize = headlineFont.pointSize * 5.0 / 3.0
            return headlineFont.withSize(pointSize)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        return classifiedItems.sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        
        return classifiedItems.sections[section].items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let classifiedItems = classifiedItems {
            let item = classifiedItems.sections[indexPath.section].items[indexPath.row]
            
            switch item {
            case let radical as Radical:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: radicalReuseIdentifier, for: indexPath) as! RadicalGuruProgressCollectionViewCell
                cell.dataItem = radical
                return cell
            case let kanji as Kanji:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kanjiReuseIdentifier, for: indexPath) as! KanjiGuruProgressCollectionViewCell
                cell.dataItem = kanji
                return cell
            default: fatalError("Only Radicals and Kanji are supported by \(type(of: self))")
            }
        } else {
            fatalError("Neither kanji or radicals set, yet it tried to dequeue a cell")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! SRSItemHeaderCollectionReusableView
        
        if kind == UICollectionElementKindSectionHeader {
            let section = classifiedItems?.sections[indexPath.section]
            view.headerLabel.font = headerFont
            view.headerLabel.text = section?.title
        } else {
            view.headerLabel.text = nil
        }
        
        return view
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SRSDataItemInfoURL, let url = cell.srsDataItemInfoURL else { return }
        
        self.present(WKWebViewController.wrapped(url: url) { $0.delegate = self }, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let label = UILabel()
        label.font = headerFont
        label.text = "Remaining to Level"
        label.sizeToFit()
        
        let insets = (collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        return CGSize(width: collectionView.bounds.width, height: label.bounds.height + insets.top + insets.bottom)
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(_ controller: WKWebViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect = UIBlurEffect(style: .extraLight)
        
        let backgroundView = UIView(frame: collectionView!.frame)
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        let imageView = UIImageView(image: UIImage(named: "Art03"))
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.contentMode = .scaleAspectFill
        imageView.frame = backgroundView.frame
        backgroundView.addSubview(imageView)
        let visualEffectBlurView = UIVisualEffectView(effect: blurEffect)
        visualEffectBlurView.frame = imageView.frame
        visualEffectBlurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.addSubview(visualEffectBlurView)
        let darkenView = UIView(frame: visualEffectBlurView.frame)
        darkenView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        darkenView.alpha = 0.1
        darkenView.backgroundColor = ApplicationSettings.globalTintColor
        visualEffectBlurView.contentView.addSubview(darkenView)
        collectionView!.backgroundView = backgroundView
    }
}
