//
//  NetworkIndicatorController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation
import UIKit
import WaniKaniKit

class NetworkIndicatorController: NetworkActivityDelegate {
    static let shared = NetworkIndicatorController()
    
    private var activityCount = 0
    private var visibilityTimer: Timer?
    
    func networkActivityDidStart() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
        
        activityCount += 1
        
        updateIndicatorVisibility()
    }
    
    func networkActivityDidFinish() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
        
        activityCount -= 1
        
        updateIndicatorVisibility()
    }
    
    private func updateIndicatorVisibility() {
        if activityCount > 0 {
            showIndicator()
        } else {
            // To prevent the indicator from flickering on and off, we delay the
            // hiding of the indicator by one second. This provides the chance
            // to come in and invalidate the timer before it fires.
            visibilityTimer = Timer(interval: 1.0) {
                self.hideIndicator()
            }
        }
    }
    
    private func showIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    private func hideIndicator() {
        visibilityTimer?.cancel()
        visibilityTimer = nil
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

private class Timer {
    private var isCancelled = false
    
    init(interval: TimeInterval, handler: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            if self?.isCancelled == false {
                handler()
            }
        }
    }
    
    func cancel() {
        isCancelled = true
    }
}
