import CoreText
import UIKit

struct RubyAnnotatedCharacters {
    let characters: String
    let furigana: String?
}

//@IBDesignable
final class RubyLabel: UIView {
    @IBInspectable var orientation: NSTextLayoutOrientation = .vertical {
        didSet {
            rebuildAttributedText()
        }
    }
    
    @IBInspectable var font: UIFont? {
        didSet {
            rebuildAttributedText()
        }
    }
    
    @IBInspectable var textColor: UIColor? {
        didSet {
            rebuildAttributedText()
        }
    }

    @IBInspectable var text: String? {
        get {
            if let characters = rubyCharacters {
                return characters.map({ $0.characters }).joined(separator: "")
            } else {
                return nil
            }
        }
        set {
            if let value = newValue {
                rubyCharacters = [RubyAnnotatedCharacters(characters: value, furigana: nil)]
            } else {
                rubyCharacters = nil
            }
        }
    }

    @IBInspectable var rubyCharacters: [RubyAnnotatedCharacters]? {
        didSet {
            rebuildAttributedText()
        }
    }

    private var attributedText: CFAttributedString?
    
    private func rebuildAttributedText() {
        guard let rubyCharacters = self.rubyCharacters else {
            attributedText = nil
            return
        }
        
        let attrString: CFMutableAttributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0)
        CFAttributedStringBeginEditing(attrString);
        for char in rubyCharacters {
            // Add chars
            let location = CFAttributedStringGetLength(attrString)
            CFAttributedStringReplaceString(attrString, CFRangeMake(location, 0), char.characters as CFString)
            let length = CFAttributedStringGetLength(attrString) - location
            let characterRange = CFRangeMake(location, length)
            
            // Add furigana
            let furiganaArraySize = Int(CTRubyPosition.count.rawValue)
            let furiganaArray = UnsafeMutablePointer<Unmanaged<CFString>>.allocate(capacity: furiganaArraySize)
            defer { furiganaArray.deinitialize() }
            
            for i in 0..<furiganaArraySize {
                // This probably isn't correct, but the Unmanaged<CFString> is no longer optional so ¯\_(ツ)_/¯
                furiganaArray[i] = Unmanaged.passUnretained("" as CFString)
            }
            if let furigana = char.furigana {
                furiganaArray[Int(CTRubyPosition.before.rawValue)] = Unmanaged.passUnretained(furigana as CFString)
            }
            
            let rubyRef = CTRubyAnnotationCreate(CTRubyAlignment.auto, CTRubyOverhang.auto, 0.5, furiganaArray)

            CFAttributedStringSetAttribute(attrString, characterRange, kCTRubyAnnotationAttributeName, rubyRef);
        }

        let wholeStringRange = CFRangeMake(0, CFAttributedStringGetLength(attrString))
        if let font = self.font {
            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSFontAttributeName as CFString, font);
        }
        if let textColor = self.textColor {
            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSForegroundColorAttributeName as CFString, textColor);
        }
        
        if orientation == .vertical {
            let para = NSMutableParagraphStyle()
            para.lineHeightMultiple = 1

            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSParagraphStyleAttributeName as CFString, para);
            CFAttributedStringSetAttribute(attrString, wholeStringRange, kCTVerticalFormsAttributeName, NSNumber(value: true));
        }
        CFAttributedStringEndEditing(attrString);

        attributedText = attrString
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let rubyString = self.attributedText else {
            return
        }
        
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.textMatrix = CGAffineTransform.identity
        
        // Flip the context coordinates, in iOS only.
        context.translateBy(x: 0, y: self.bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let frameSetter = CTFramesetterCreateWithAttributedString(rubyString)
        let path = CGPath(rect: bounds, transform: nil)
        
        let frameAttributes: [NSString: AnyObject]?
        if orientation == .vertical {
            frameAttributes = [kCTFrameProgressionAttributeName: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)]
        } else {
            frameAttributes = nil
        }
        
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), path, frameAttributes as CFDictionary?)

        CTFrameDraw(frame, context)
    }
    
    override var intrinsicContentSize: CGSize {
        guard let rubyString = self.attributedText else {
            return CGSize.zero
        }

        let framesetter = CTFramesetterCreateWithAttributedString(rubyString)

        let frameAttributes: [NSString: AnyObject]?
        let constraints: CGSize
        if orientation == .vertical {
            frameAttributes = [kCTFrameProgressionAttributeName: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)]
            constraints = CGSize(width: CGFloat.greatestFiniteMagnitude, height: superview?.bounds.size.height ?? CGFloat.greatestFiniteMagnitude)
        }
        else {
            frameAttributes = nil
            constraints = CGSize(width: superview?.bounds.size.width ?? CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }

        let fitrange: UnsafeMutablePointer<CFRange>? = nil
        defer { fitrange?.deinitialize() }

        let newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), frameAttributes as CFDictionary?, constraints, fitrange)
        
        return newSize
    }

}
