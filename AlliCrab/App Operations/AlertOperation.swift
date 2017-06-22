/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to present an alert as part of an operation.
*/

import UIKit
import OperationKit
import WaniKaniKit

class AlertOperation: OperationKit.Operation {
    
    // MARK: Properties
    
    private let presentationContext: UIViewController?
    private var actions: [UIAlertAction] = []
    
    var title: String? {
        didSet {
            name = title
        }
    }
    
    var message: String?
    
    // MARK: Initialization
    
    init(presentationContext: UIViewController? = nil) {
        self.presentationContext = presentationContext ?? UIApplication.shared.keyWindow?.rootViewController
        
        super.init()
        
        addCondition(AlertPresentation())
        
        /*
        This operation modifies the view controller hierarchy.
        Doing this while other such operations are executing can lead to
        inconsistencies in UIKit. So, let's make them mutally exclusive.
        */
        addCondition(MutuallyExclusive<UIViewController>())
    }
    
    func addAction(_ title: String, style: UIAlertActionStyle = .default, handler: @escaping (AlertOperation) -> Void = { _ in }) {
        let action = UIAlertAction(title: title, style: style) { [weak self] _ in
            if let strongSelf = self {
                handler(strongSelf)
            }
            
            self?.finish()
        }
        
        actions.append(action)
    }
    
    override func execute() {
        guard let presentationContext = presentationContext else {
            finish()
            
            return
        }
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            alertController.title = self.title
            alertController.message = self.message
            if self.actions.isEmpty {
                self.addAction("OK")
            }
            self.actions.forEach { alertController.addAction($0) }
            
            presentationContext.present(alertController, animated: true, completion: nil)
        }
    }
}
