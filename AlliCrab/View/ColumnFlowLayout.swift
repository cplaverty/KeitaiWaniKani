//
//  ColumnFlowLayout.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import os
import UIKit

class ColumnFlowLayout: UICollectionViewFlowLayout {
    
    @IBInspectable var minimumColumnWidth: CGFloat = 0.0
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else {
            return
        }
        
        let edgeInsets: UIEdgeInsets
        if #available(iOS 11.0, *) {
            switch sectionInsetReference {
            case .fromContentInset:
                edgeInsets = collectionView.contentInset
            case .fromLayoutMargins:
                edgeInsets = collectionView.layoutMargins
            case .fromSafeArea:
                edgeInsets = collectionView.safeAreaInsets
            @unknown default:
                edgeInsets = collectionView.safeAreaInsets
            }
        } else {
            edgeInsets = collectionView.layoutMargins
        }
        
        let availableWidth = collectionView.bounds.inset(by: edgeInsets).inset(by: sectionInset).size.width
        let effectiveMinimumWidth = minimumColumnWidth <= 0 ? availableWidth : min(minimumColumnWidth, availableWidth)
        let columnCount = (availableWidth / effectiveMinimumWidth).rounded(.down)
        let cellWidth = ((availableWidth - minimumInteritemSpacing * (columnCount - 1)) / columnCount).rounded(.down)
        
        os_log("Total width %.2f, calculated column count %.0f with width %.0f.  Current item size: %@", type: .debug, availableWidth, columnCount, cellWidth, itemSize.debugDescription)
        
        itemSize = CGSize(width: cellWidth, height: itemSize.height)
    }
    
}
