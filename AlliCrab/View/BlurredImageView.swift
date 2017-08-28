//
//  BlurredImageView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class BlurredImageView: UIView {
    
    init(frame: CGRect, imageNamed name: String, style: UIBlurEffectStyle) {
        super.init(frame: frame)
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let imageView = UIImageView(image: UIImage(named: name))
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.contentMode = .scaleAspectFill
        imageView.frame = frame
        
        let visualEffectBlurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        visualEffectBlurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        visualEffectBlurView.frame = imageView.frame
        
        addSubview(imageView)
        addSubview(visualEffectBlurView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
