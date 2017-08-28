//
//  RequestTypes.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum StandaloneResourceRequestType {
    case user
    
    public func url(from endpoints: Endpoints) -> URL {
        switch self {
        case .user: return endpoints.user
        }
    }
}

public enum ResourceCollectionItemRequestType {
    case subject(id: Int)
    case assignment(id: Int)
    case reviewStatistic(id: Int)
    case studyMaterial(id: Int)
    
    public func url(from endpoints: Endpoints) -> URL {
        switch self {
        case .subject(id: let id): return endpoints.subjects.appendingPathComponent(String(id))
        case .assignment(id: let id): return endpoints.assignments.appendingPathComponent(String(id))
        case .reviewStatistic(id: let id): return endpoints.reviewStatistics.appendingPathComponent(String(id))
        case .studyMaterial(id: let id): return endpoints.studyMaterials.appendingPathComponent(String(id))
        }
    }
}

public enum ResourceCollectionRequestType {
    case subjects(filter: SubjectFilter?)
    case assignments(filter: AssignmentFilter?)
    case reviewStatistics(filter: ReviewStatisticFilter?)
    case studyMaterials(filter: StudyMaterialFilter?)
    
    public func url(from endpoints: Endpoints) -> URL {
        switch self {
        case .subjects(filter: let filter): return appendQueryString(for: filter, to: endpoints.subjects)
        case .assignments(filter: let filter): return appendQueryString(for: filter, to: endpoints.assignments)
        case .reviewStatistics(filter: let filter): return appendQueryString(for: filter, to: endpoints.reviewStatistics)
        case .studyMaterials(filter: let filter): return appendQueryString(for: filter, to: endpoints.studyMaterials)
        }
    }
    
    private func appendQueryString(for filter: RequestFilter?, to url: URL) -> URL {
        guard let filter = filter, let queryItems = filter.asQueryItems() else { return url }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
}
