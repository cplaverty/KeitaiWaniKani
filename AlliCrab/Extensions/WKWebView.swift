//
//  WKWebView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import WebKit

extension WKWebView {
    // Adapted from https://github.com/Telerik-Verified-Plugins/WKWebView/commit/04e8296adeb61f289f9c698045c19b62d080c7e3
    func keyboardDisplayDoesNotRequireUserAction() {
        if #available(iOS 11.3, *) {
            typealias SelectorImpType = @convention(c) (AnyObject, Selector, OpaquePointer, Bool, Bool, Bool, AnyObject) -> Void
            
            let name: String
            if #available(iOS 12.2, *) {
                name = "_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:"
            } else {
                name = "_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:"
            }
            
            swizzleMethod(name: name, type: SelectorImpType.self) { sel, msgSend -> Any in
                let block: @convention(block) (AnyObject, OpaquePointer, Bool, Bool, Bool, AnyObject) -> Void = {
                    msgSend($0, sel, $1, true, $3, $4, $5)
                }
                
                return block
            }
        } else {
            typealias SelectorImpType = @convention(c) (AnyObject, Selector, OpaquePointer, Bool, Bool, AnyObject) -> Void
            
            let name = "_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:"
            swizzleMethod(name: name, type: SelectorImpType.self) { sel, msgSend -> Any in
                let block: @convention(block) (AnyObject, OpaquePointer, Bool, Bool, AnyObject) -> Void = {
                    msgSend($0, sel, $1, true, $3, $4)
                }
                
                return block
            }
        }
    }
    
    private func swizzleMethod<SelectorImpType>(name: String, type selImpType: SelectorImpType.Type, blockFactory: (Selector, SelectorImpType) -> Any) {
        guard let cls = NSClassFromString("WKContentView") else {
            os_log("Failed to find appropriate class to swizzle", type: .error)
            return
        }
        
        let sel = sel_getUid(name)
        guard let method = class_getInstanceMethod(cls, sel) else {
            os_log("Failed to find appropriate method to swizzle", type: .error)
            return
        }
        
        let originalImp = method_getImplementation(method)
        let impAsSelectorType = unsafeBitCast(originalImp, to: selImpType)
        let block = blockFactory(sel, impAsSelectorType)
        let imp = imp_implementationWithBlock(block)
        method_setImplementation(method, imp)
    }
}
