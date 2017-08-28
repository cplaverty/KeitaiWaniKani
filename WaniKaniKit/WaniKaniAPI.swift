//
//  WaniKaniAPI.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os

public protocol WaniKaniAPIProtocol {
    func fetchResource(ofType type: StandaloneResourceRequestType, completionHandler: @escaping (StandaloneResource?, Error?) -> Void) -> Progress
    func fetchResource(ofType type: ResourceCollectionItemRequestType, completionHandler: @escaping (ResourceCollectionItem?, Error?) -> Void) -> Progress
    func fetchResourceCollection(ofType type: ResourceCollectionRequestType, completionHandler: @escaping (ResourceCollection?, Error?) -> Bool) -> Progress
}

public protocol NetworkActivityDelegate: class {
    func networkActivityDidStart()
    func networkActivityDidFinish()
}

private class Request {
    let progress: Progress
    var tasks = [URLSessionDataTask]()
    
    init() {
        progress = Progress(totalUnitCount: -1)
        progress.isCancellable = true
        progress.isPausable = true
        
        progress.cancellationHandler = cancel
        progress.pausingHandler = suspend
        progress.resumingHandler = resume
    }
    
    deinit {
        if #available(iOS 10, *) {
            os_log("Marking progress complete for request (was %jd of %jd)", type: .debug, progress.completedUnitCount, progress.totalUnitCount)
        }
        progress.totalUnitCount = min(progress.totalUnitCount, 1)
        progress.completedUnitCount = min(progress.totalUnitCount, 1)
    }
    
    var isCancelled: Bool {
        return progress.isCancelled
    }
    
    var isPaused: Bool {
        return progress.isPaused
    }
    
    func cancel() {
        tasks.forEach { task in
            task.cancel()
        }
    }
    
    func suspend() {
        tasks.forEach { task in
            task.suspend()
        }
    }
    
    func resume() {
        tasks.forEach { task in
            task.resume()
        }
    }
}

public class WaniKaniAPI: WaniKaniAPIProtocol {
    public let apiKey: String
    
    public weak var networkActivityDelegate: NetworkActivityDelegate?
    
    private let endpoints: Endpoints
    private let decoder: ResourceDecoder
    private let session: URLSession
    
    public init(apiKey: String,
                endpoints: Endpoints = Endpoints.default,
                decoder: ResourceDecoder = WaniKaniResourceDecoder()) {
        self.apiKey = apiKey
        self.endpoints = endpoints
        self.decoder = decoder
        
        let config = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            config.waitsForConnectivity = true
        }
        
        session = URLSession(configuration: config)
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    public func fetchResource(ofType type: StandaloneResourceRequestType, completionHandler: @escaping (StandaloneResource?, Error?) -> Void) -> Progress {
        return fetchResource(with: type.url(from: endpoints), completionHandler: completionHandler)
    }
    
    public func fetchResource(ofType type: ResourceCollectionItemRequestType, completionHandler: @escaping (ResourceCollectionItem?, Error?) -> Void) -> Progress {
        return fetchResource(with: type.url(from: endpoints), completionHandler: completionHandler)
    }
    
    private func fetchResource<T: Decodable>(with url: URL, completionHandler: @escaping (T?, Error?) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        progress.isCancellable = true
        progress.isPausable = true
        
        let task = dataTask(with: url) { (data, response, error) in
            defer { progress.completedUnitCount = 1 }
            do {
                let resource = try self.parseResource(T.self, data: data, response: response, error: error)
                completionHandler(resource, error)
            } catch let error as URLError where error.code == .cancelled {
                // Ignore cancellation errors
            } catch {
                completionHandler(nil, error)
            }
        }
        progress.cancellationHandler = { task.cancel() }
        progress.pausingHandler = { task.suspend() }
        progress.resumingHandler = { task.resume() }
        
        task.resume()
        
        return progress
    }
    
    public func fetchResourceCollection(ofType type: ResourceCollectionRequestType, completionHandler: @escaping (ResourceCollection?, Error?) -> Bool) -> Progress {
        let request = Request()
        
        let task = fetchResourceCollection(with: type.url(from: endpoints), request: request, allPagesFetched: false, completionHandler: completionHandler)
        request.tasks.append(task)
        
        return request.progress
    }
    
    private func fetchResourceCollection(with url: URL, request: Request, allPagesFetched: Bool, completionHandler: @escaping (ResourceCollection?, Error?) -> Bool) -> URLSessionDataTask {
        let task = dataTask(with: url) { (data, response, error) in
            defer { request.progress.completedUnitCount += 1 }
            do {
                let resources = try self.parseResource(ResourceCollection.self, data: data, response: response, error: error)
                
                if let pages = resources?.pages {
                    request.progress.totalUnitCount = Int64(pages.lastNumber)
                    
                    guard !request.isCancelled else { return }
                    
                    if !allPagesFetched {
                        if let allPages = self.getAllLocations(for: pages) {
                            allPages.forEach { nextPage in
                                request.tasks.append(self.fetchResourceCollection(with: nextPage, request: request, allPagesFetched: true, completionHandler: completionHandler))
                            }
                        } else if let nextPage = pages.nextURL {
                            request.tasks.append(self.fetchResourceCollection(with: nextPage, request: request, allPagesFetched: false, completionHandler: completionHandler))
                        }
                    }
                } else {
                    request.progress.totalUnitCount = 1
                }
                
                guard !request.isCancelled else { return }
                
                let shouldGetNextPage = completionHandler(resources, error)
                if !shouldGetNextPage {
                    request.cancel()
                }
            } catch let error as URLError where error.code == .cancelled {
                // Do not notify errors due to cancellation
            } catch {
                _ = completionHandler(nil, error)
            }
        }
        
        if !request.isCancelled && !request.isPaused {
            task.resume()
        }
        
        return task
    }
    
    private func getAllLocations(for pages: ResourceCollection.Pages) -> [URL]? {
        let pageQueryItemName = "page"
        guard let nextPage = pages.nextURL else {
            return []
        }
        
        guard let urlComponents = URLComponents(url: nextPage, resolvingAgainstBaseURL: true),
            let queryItem = urlComponents.queryItems,
            let pageQueryItemIndex = queryItem.index(where: { queryItem in queryItem.name == pageQueryItemName }) else {
                return nil
        }
        
        let startingPage = queryItem[pageQueryItemIndex].value.flatMap { Int($0) } ?? pages.currentNumber + 1
        
        let pages: [URL] = (startingPage...pages.lastNumber).map { pageNumber in
            var newComponents = urlComponents
            newComponents.queryItems![pageQueryItemIndex] = URLQueryItem(name: "page", value: String(pageNumber))
            return newComponents.url!
        }
        
        return pages
    }
    
    private func parseResource<T: Decodable>(_ type: T.Type, data: Data?, response: URLResponse?, error: Error?) throws -> T? {
        if let error = error {
            throw error
        }
        
        let httpResponse = response as? HTTPURLResponse
        let httpStatusCode: Int = httpResponse?.statusCode ?? 200
        let httpStatusCodeDescription = HTTPURLResponse.localizedString(forStatusCode: httpStatusCode)
        
        if #available(iOS 10.0, *) {
            if let data = data {
                os_log("Response: %@ (%d), %{iec-bytes}d received", type: .debug, httpStatusCodeDescription, httpStatusCode, data.count)
            } else {
                os_log("Response: %@ (%d) <no data>", type: .debug, httpStatusCodeDescription, httpStatusCode)
            }
        }
        
        switch httpStatusCode {
        case 200:
            guard let data = data else { throw WaniKaniAPIError.noContent }
            return try self.decoder.decode(type, from: data)
        case 304:
            return nil
        case 400..<500:
            let errorMessage: String
            if let data = data, let error = try? self.decoder.decode(APIError.self, from: data) {
                errorMessage = error.message
            } else {
                errorMessage = httpStatusCodeDescription
            }
            
            if #available(iOS 10.0, *) {
                os_log("Error message received: %@", type: .debug, errorMessage)
            }
            
            switch httpStatusCode {
            case 401:
                throw WaniKaniAPIError.invalidAPIKey
            case 404:
                throw WaniKaniAPIError.resourceNotFound
            default:
                throw WaniKaniAPIError.unknownError(httpStatusCode: httpStatusCode, message: errorMessage)
            }
        default:
            throw WaniKaniAPIError.unhandledStatusCode(httpStatusCode: httpStatusCode, data: data)
        }
    }
    
    private func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Token token=\(apiKey)", forHTTPHeaderField: "Authorization")
        
        if #available(iOS 10.0, *) {
            os_log("Initiating request for %@", type: .debug, url.absoluteString)
        }
        
        let task = session.dataTask(with: urlRequest, completionHandler: completionHandler)
        addTaskStateListener(task)
        
        return task
    }
    
    private func addTaskStateListener(_ task: URLSessionTask) {
        guard let networkActivityDelegate = self.networkActivityDelegate else {
            return
        }
        
        var running = false
        var observer: NSKeyValueObservation! = nil
        observer = task.observe(\.state) { (task, change) in
            DispatchQueue.main.async {
                switch task.state {
                case .running:
                    guard !running else {
                        if #available(iOS 10.0, *) {
                            os_log("Ignoring duplicate state change for task with identifier %d triggering network activity start", type: .debug, task.taskIdentifier)
                        }
                        return
                    }
                    if #available(iOS 10.0, *) {
                        os_log("Task with identifier %d triggering network activity start", type: .debug, task.taskIdentifier)
                    }
                    networkActivityDelegate.networkActivityDidStart()
                    running = true
                case .suspended:
                    guard running else {
                        if #available(iOS 10.0, *) {
                            os_log("Ignoring duplicate state change for task with identifier %d triggering network activity finish", type: .debug, task.taskIdentifier)
                        }
                        return
                    }
                    if #available(iOS 10.0, *) {
                        os_log("Task with identifier %d triggering network activity finish", type: .debug, task.taskIdentifier)
                    }
                    networkActivityDelegate.networkActivityDidFinish()
                    running = false
                case .canceling, .completed:
                    guard running else {
                        if #available(iOS 10.0, *) {
                            os_log("Ignoring duplicate state change for task with identifier %d triggering network activity finish (terminal state)", type: .debug, task.taskIdentifier)
                        }
                        return
                    }
                    if #available(iOS 10.0, *) {
                        os_log("Task with identifier %d triggering network activity finish (terminal state)", type: .debug, task.taskIdentifier)
                    }
                    guard running else { return }
                    networkActivityDelegate.networkActivityDidFinish()
                    running = false
                    observer.invalidate()
                }
            }
        }
    }
    
    private struct APIError: Codable {
        let message: String
        
        private enum CodingKeys: String, CodingKey {
            case message = "error"
        }
    }
}
