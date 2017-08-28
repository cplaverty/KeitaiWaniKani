//
//  UIColor.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public extension UIColor {
    class var waniKaniRadical: UIColor {
        return makeFromWebColor(red: 0x00, green: 0xa1, blue: 0xf1)
    }
    class var waniKaniKanji: UIColor {
        return makeFromWebColor(red: 0xf1, green: 0x00, blue: 0xa1)
    }
    class var waniKaniVocabulary: UIColor {
        return makeFromWebColor(red: 0xa1, green: 0x00, blue: 0xf1)
    }
    
    class var waniKaniApprentice: UIColor {
        return makeFromWebColor(red: 0xdd, green: 0x00, blue: 0x93)
    }
    class var waniKaniGuru: UIColor {
        return makeFromWebColor(red: 0x88, green: 0x2d, blue: 0x9e)
    }
    class var waniKaniMaster: UIColor {
        return makeFromWebColor(red: 0x29, green: 0x4d, blue: 0xdb)
    }
    class var waniKaniEnlightened: UIColor {
        return makeFromWebColor(red: 0x00, green: 0x93, blue: 0xdd)
    }
    class var waniKaniBurned: UIColor {
        return makeFromWebColor(red: 0x43, green: 0x43, blue: 0x43)
    }
    
    private static func makeFromWebColor(red: Int, green: Int, blue: Int) -> UIColor {
        let max = CGFloat(0xff)
        return UIColor(red: CGFloat(red) / max, green: CGFloat(green) / max, blue: CGFloat(blue) / max, alpha: 1.0)
    }
}
