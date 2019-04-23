//
//  MockWaniKaniAPI.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WaniKaniKit

class MockWaniKaniAPI: WaniKaniAPIProtocol {
    let standaloneResourceLocator: ((StandaloneResourceRequestType) -> Result<StandaloneResource, Error>)?
    let resourceCollectionItemLocator: ((ResourceCollectionItemRequestType) -> Result<ResourceCollectionItem, Error>)?
    let resourceCollectionLocator: ((ResourceCollectionRequestType) -> Result<ResourceCollection, Error>)?
    
    init(
        standaloneResourceLocator: ((StandaloneResourceRequestType) -> Result<StandaloneResource, Error>)? = nil,
        resourceCollectionItemLocator: ((ResourceCollectionItemRequestType) -> Result<ResourceCollectionItem, Error>)? = nil,
        resourceCollectionLocator: ((ResourceCollectionRequestType) -> Result<ResourceCollection, Error>)? = nil
        ) {
        self.standaloneResourceLocator = standaloneResourceLocator
        self.resourceCollectionItemLocator = resourceCollectionItemLocator
        self.resourceCollectionLocator = resourceCollectionLocator
    }
    
    func fetchResource(ofType type: StandaloneResourceRequestType, completionHandler: @escaping (Result<StandaloneResource, Error>) -> Void) -> Progress {
        guard let standaloneResourceLocator = standaloneResourceLocator else {
            fatalError()
        }
        
        let result = standaloneResourceLocator(type)
        completionHandler(result)
        return Progress(totalUnitCount: -1)
    }
    
    func fetchResource(ofType type: ResourceCollectionItemRequestType, completionHandler: @escaping (Result<ResourceCollectionItem, Error>) -> Void) -> Progress {
        guard let resourceCollectionItemLocator = resourceCollectionItemLocator else {
            fatalError()
        }
        
        let result = resourceCollectionItemLocator(type)
        completionHandler(result)
        return Progress(totalUnitCount: -1)
    }
    
    func fetchResourceCollection(ofType type: ResourceCollectionRequestType, completionHandler: @escaping (Result<ResourceCollection, Error>) -> Bool) -> Progress {
        guard let resourceCollectionLocator = resourceCollectionLocator else {
            fatalError()
        }
        
        let result = resourceCollectionLocator(type)
        _ = completionHandler(result)
        return Progress(totalUnitCount: -1)
    }
}
