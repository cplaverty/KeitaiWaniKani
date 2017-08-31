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
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textAlignment = .center
        label.textColor = .black
        if #available(iOS 10.0, *) {
            label.adjustsFontForContentSizeCategory = true
        }
        
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
                DispatchQueue.main.async {
                    self?.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                }
            },
            progress.observe(\.isCancelled) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.markComplete()
                }
            }]
    }
    
    func markComplete() {
        observers = nil
        trackedProgress = nil
        progressView.setProgress(1, animated: true)
        UIView.animate(withDuration: 0.5, delay: 0.25, options: [.curveEaseIn], animations: {
            self.progressView.alpha = 0.0
        })
        progressView.setProgress(0, animated: false)
        textLabel.text = nil
    }
}
