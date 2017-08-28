//
//  UIBottomBorderedView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class UIBottomBorderedView: UIView {
    private let borderLayer: CALayer
    private let borderWidth: CGFloat
    
    init(frame: CGRect, color: UIColor, width: CGFloat) {
        borderLayer = CALayer()
        borderLayer.backgroundColor = color.cgColor
        borderWidth = width
        super.init(frame: frame)
        self.layer.addSublayer(borderLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = CGRect(x: 0, y: max(0, self.frame.size.height - borderWidth), width: self.frame.size.width, height: borderWidth)
    }
}
