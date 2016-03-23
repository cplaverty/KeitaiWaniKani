import CoreText
import UIKit

struct RubyAnnotatedCharacters {
    let characters: String
    let furigana: String?
}

//@IBDesignable
final class RubyLabel: UIView {
    @IBInspectable var orientation: NSTextLayoutOrientation = .Vertical {
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
                return characters.map({ $0.characters }).joinWithSeparator("")
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
            CFAttributedStringReplaceString(attrString, CFRangeMake(location, 0), char.characters)
            let length = CFAttributedStringGetLength(attrString) - location
            let characterRange = CFRangeMake(location, length)
            
            // Add furigana
            let furiganaArraySize = 4 //Int(CTRubyPosition.Count.rawValue)
            let furiganaArray = UnsafeMutablePointer<Unmanaged<CFString>?>.alloc(furiganaArraySize)
            defer { furiganaArray.destroy() }
            
            for i in 0..<furiganaArraySize {
                furiganaArray[i] = nil
            }
            if let furigana = char.furigana {
                furiganaArray[Int(CTRubyPosition.Before.rawValue)] = Unmanaged.passRetained(furigana)
            }
            
            let rubyRef = CTRubyAnnotationCreate(CTRubyAlignment.Auto, CTRubyOverhang.Auto, 0.5, furiganaArray)

            CFAttributedStringSetAttribute(attrString, characterRange, kCTRubyAnnotationAttributeName, rubyRef);
        }

        let wholeStringRange = CFRangeMake(0, CFAttributedStringGetLength(attrString))
        if let font = self.font {
            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSFontAttributeName, font);
        }
        if let textColor = self.textColor {
            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSForegroundColorAttributeName, textColor);
        }
        
        if orientation == .Vertical {
            let para = NSMutableParagraphStyle()
            para.lineHeightMultiple = 1

            CFAttributedStringSetAttribute(attrString, wholeStringRange, NSParagraphStyleAttributeName, para);
            CFAttributedStringSetAttribute(attrString, wholeStringRange, kCTVerticalFormsAttributeName, NSNumber(bool: true));
        }
        CFAttributedStringEndEditing(attrString);

        attributedText = attrString
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        guard let rubyString = self.attributedText else {
            return
        }
        
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        CGContextSetTextMatrix(context, CGAffineTransformIdentity)
        
        // Flip the context coordinates, in iOS only.
        CGContextTranslateCTM(context, 0, self.bounds.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        let frameSetter = CTFramesetterCreateWithAttributedString(rubyString)
        let path = CGPathCreateWithRect(bounds, nil)
        
        let frameAttributes: [NSString: AnyObject]?
        if orientation == .Vertical {
            frameAttributes = [kCTFrameProgressionAttributeName: NSNumber(unsignedInt: CTFrameProgression.RightToLeft.rawValue)]
        } else {
            frameAttributes = nil
        }
        
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), path, frameAttributes)

        CTFrameDraw(frame, context)
    }
    
    override func intrinsicContentSize() -> CGSize {
        guard let rubyString = self.attributedText else {
            return CGSize.zero
        }

        let framesetter = CTFramesetterCreateWithAttributedString(rubyString)

        let frameAttributes: [NSString: AnyObject]?
        let constraints: CGSize
        if orientation == .Vertical {
            frameAttributes = [kCTFrameProgressionAttributeName: NSNumber(unsignedInt: CTFrameProgression.RightToLeft.rawValue)]
            constraints = CGSizeMake(CGFloat.max, superview?.bounds.size.height ?? CGFloat.max)
        }
        else {
            frameAttributes = nil
            constraints = CGSizeMake(superview?.bounds.size.width ?? CGFloat.max, CGFloat.max)
        }

        let fitrange: UnsafeMutablePointer<CFRange> = nil
        defer { fitrange.destroy() }

        let newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), frameAttributes, constraints, fitrange)
        
        return newSize
    }

}
