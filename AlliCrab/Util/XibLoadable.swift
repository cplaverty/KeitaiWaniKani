//
//  XibLoadable.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit

protocol XibLoadable {
    var xibName: String { get }
}

extension XibLoadable where Self: UIView {
    var xibName: String {
        get {
            return String(describing: type(of: self))
        }
    }
    
    func loadViewFromXib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: xibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }
}
