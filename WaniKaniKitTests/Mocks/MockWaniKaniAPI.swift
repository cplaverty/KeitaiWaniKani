//
//  MockWaniKaniAPI.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WaniKaniKit

class MockWaniKaniAPI: WaniKaniAPIProtocol {
    let standaloneResourceLocator: ((StandaloneResourceRequestType) -> (StandaloneResource?, Error?))?
    let resourceCollectionItemLocator: ((ResourceCollectionItemRequestType) -> (ResourceCollectionItem?, Error?))?
    let resourceCollectionLocator: ((ResourceCollectionRequestType) -> (ResourceCollection?, Error?))?
    
    init(
        standaloneResourceLocator: ((StandaloneResourceRequestType) -> (StandaloneResource?, Error?))? = nil,
        resourceCollectionItemLocator: ((ResourceCollectionItemRequestType) -> (ResourceCollectionItem?, Error?))? = nil,
        resourceCollectionLocator: ((ResourceCollectionRequestType) -> (ResourceCollection?, Error?))? = nil
        ) {
        self.standaloneResourceLocator = standaloneResourceLocator
        self.resourceCollectionItemLocator = resourceCollectionItemLocator
        self.resourceCollectionLocator = resourceCollectionLocator
    }
    
    func fetchResource(ofType type: StandaloneResourceRequestType, completionHandler: @escaping (StandaloneResource?, Error?) -> Void) -> Progress {
        guard let standaloneResourceLocator = standaloneResourceLocator else {
            fatalError()
        }
        
        let (resource, error) = standaloneResourceLocator(type)
        completionHandler(resource, error)
        return Progress(totalUnitCount: -1)
    }
    
    func fetchResource(ofType type: ResourceCollectionItemRequestType, completionHandler: @escaping (ResourceCollectionItem?, Error?) -> Void) -> Progress {
        guard let resourceCollectionItemLocator = resourceCollectionItemLocator else {
            fatalError()
        }
        
        let (resource, error) = resourceCollectionItemLocator(type)
        completionHandler(resource, error)
        return Progress(totalUnitCount: -1)
    }
    
    func fetchResourceCollection(ofType type: ResourceCollectionRequestType, completionHandler: @escaping (ResourceCollection?, Error?) -> Bool) -> Progress {
        guard let resourceCollectionLocator = resourceCollectionLocator else {
            fatalError()
        }
        
        let (resource, error) = resourceCollectionLocator(type)
        _ = completionHandler(resource, error)
        return Progress(totalUnitCount: -1)
    }
}
