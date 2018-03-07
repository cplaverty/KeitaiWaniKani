//
//  WKWebView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WebKit

private var swizzledClassMapping: [AnyClass] = []

extension WKWebView {
    // Adapted from http://stackoverflow.com/questions/19033292/ios-7-uiwebview-keyboard-issue?lq=1
    @objc func noInputAccessoryView() -> UIView? {
        return nil
    }
    
    func removeInputAccessoryView() {
        guard let subview = scrollView.subviews.filter({ NSStringFromClass(type(of: $0)).hasPrefix("WKContent") }).first else {
            return
        }
        
        // Guard in case this method is called twice on the same webview.
        guard !(swizzledClassMapping as NSArray).contains(type(of: subview)) else {
            return
        }
        
        let className = "\(type(of: subview))_SwizzleHelper"
        var newClass: AnyClass? = NSClassFromString(className)
        
        if newClass == nil {
            newClass = objc_allocateClassPair(type(of: subview), className, 0)
            
            guard newClass != nil else {
                return
            }
            
            if let method = class_getInstanceMethod(type(of: self), #selector(noInputAccessoryView)) {
                class_addMethod(newClass!, #selector(getter: UIResponder.inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method))
                
                objc_registerClassPair(newClass!)
                
                swizzledClassMapping += [newClass!]
            }
        }
        
        object_setClass(subview, newClass!)
    }
    
    // Adapted from https://github.com/Telerik-Verified-Plugins/WKWebView/commit/04e8296adeb61f289f9c698045c19b62d080c7e3
    func keyboardDisplayDoesNotRequireUserAction() {
        let cls: AnyClass? = NSClassFromString("WKContentView")
        if #available(iOS 11.3, *) {
            typealias SelectorImpType = @convention(c) (AnyObject, Selector, OpaquePointer, Bool, Bool, Bool, AnyObject) -> Void
            let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
            guard let method = class_getInstanceMethod(cls, sel) else {
                return
            }
            
            let originalImp = method_getImplementation(method)
            let block: @convention(block) (AnyObject, OpaquePointer, Bool, Bool, Bool, AnyObject) -> Void = {
                let chained = unsafeBitCast(originalImp, to: SelectorImpType.self)
                chained($0, sel, $1, true, $3, $4, $5)
            }
            let imp = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        } else {
            typealias SelectorImpType = @convention(c) (AnyObject, Selector, OpaquePointer, Bool, Bool, AnyObject) -> Void
            
            let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
            guard let method = class_getInstanceMethod(cls, sel) else {
                return
            }
            
            let originalImp = method_getImplementation(method)
            let block: @convention(block) (AnyObject, OpaquePointer, Bool, Bool, AnyObject) -> Void = {
                let chained = unsafeBitCast(originalImp, to: SelectorImpType.self)
                chained($0, sel, $1, true, $3, $4)
            }
            let imp = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        }
    }
}
