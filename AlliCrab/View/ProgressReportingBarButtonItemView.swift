//
//  ProgressReportingBarButtonItemView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit

class ProgressReportingBarButtonItemView: UIView {
    let textLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        
        return label
    }()
    
    let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        progress.trackTintColor = .clear
        progress.progress = 0
        progress.alpha = 0
        
        return progress
    }()
    
    var isTrackedOperationInProgress: Bool {
        return observers != nil
    }
    
    private var trackedProgress: Progress?
    private var observers: [NSKeyValueObservation]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        textLabel.frame = CGRect(origin: .zero, size: frame.size)
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: progressView.frame.height))
        
        addSubview(textLabel)
        addSubview(progressView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func track(progress: Progress, description: String) {
        trackedProgress = progress
        textLabel.text = description
        
        progressView.setProgress(0, animated: false)
        progressView.alpha = 1.0
        progressView.setProgress(Float(progress.fractionCompleted), animated: true)
        
        observers = [
            progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                }
            },
            progress.observe(\.isCancelled) { [weak self] _, _ in
                guard let self = self else { return }
                
                self.stopTrackingProgress()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.markProgressViewComplete()
                }
            }]
    }
    
    func markComplete() {
        if !isTrackedOperationInProgress {
            return
        }
        
        stopTrackingProgress()
        markProgressViewComplete()
    }
    
    private func stopTrackingProgress() {
        observers = nil
        trackedProgress = nil
    }
    
    private func markProgressViewComplete() {
        progressView.setProgress(1, animated: true)
        UIView.animate(withDuration: 0.25, delay: 0.25, options: [.curveEaseInOut], animations: {
            self.progressView.alpha = 0.0
        }, completion: { _ in
            self.progressView.setProgress(0, animated: false)
        })
        textLabel.text = nil
    }
}
