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
        
        progress.cancellationHandler = cancelTasks
        progress.pausingHandler = suspendTasks
        progress.resumingHandler = resumeTasks
    }
    
    deinit {
        os_log("Marking progress complete for request (was %jd of %jd)", type: .debug, progress.completedUnitCount, progress.totalUnitCount)
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
        progress.cancel()
    }
    
    private func cancelTasks() {
        tasks.forEach { task in
            task.cancel()
        }
    }
    
    private func suspendTasks() {
        tasks.forEach { task in
            task.suspend()
        }
    }
    
    private func resumeTasks() {
        tasks.forEach { task in
            task.resume()
        }
    }
}

public class WaniKaniAPI: WaniKaniAPIProtocol {
    public let apiRevision = "20170710"
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
        config.timeoutIntervalForResource = .oneHour
        
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
        
        let task = dataTask(with: url) { [weak progress] (data, response, error) in
            defer { progress?.completedUnitCount = 1 }
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
        
        let task = fetchResourceCollection(with: type.url(from: endpoints), request: request, completionHandler: completionHandler)
        request.tasks.append(task)
        
        return request.progress
    }
    
    private func fetchResourceCollection(with url: URL, request: Request, completionHandler: @escaping (ResourceCollection?, Error?) -> Bool) -> URLSessionDataTask {
        let task = dataTask(with: url) { (data, response, error) in
            let resources: ResourceCollection?
            do {
                resources = try self.parseResource(ResourceCollection.self, data: data, response: response, error: error)
            } catch let error as URLError where error.code == .cancelled {
                // Do not notify errors due to cancellation
                return
            } catch {
                _ = completionHandler(nil, error)
                return
            }
            
            if let resources = resources {
                defer { request.progress.completedUnitCount += 1 }
                request.progress.totalUnitCount = Int64(resources.estimatedPageCount)
                
                guard !request.isCancelled else { return }
                
                if let nextPage = resources.pages.nextURL {
                    request.tasks.append(self.fetchResourceCollection(with: nextPage, request: request, completionHandler: completionHandler))
                }
            } else {
                defer { request.progress.completedUnitCount = 1 }
                request.progress.totalUnitCount = 1
            }
            
            guard !request.isCancelled else { return }
            
            let shouldGetNextPage = completionHandler(resources, error)
            if !shouldGetNextPage {
                request.cancel()
            }
        }
        
        if !request.isCancelled && !request.isPaused {
            task.resume()
        }
        
        return task
    }
    
    private func parseResource<T: Decodable>(_ type: T.Type, data: Data?, response: URLResponse?, error: Error?) throws -> T? {
        if let error = error {
            throw error
        }
        
        let httpResponse = response as? HTTPURLResponse
        let httpStatusCode: Int = httpResponse?.statusCode ?? 200
        let httpStatusCodeDescription = HTTPURLResponse.localizedString(forStatusCode: httpStatusCode)
        
        if let data = data {
            os_log("Response: %@ (%d), %{iec-bytes}d received", type: .debug, httpStatusCodeDescription, httpStatusCode, data.count)
        } else {
            os_log("Response: %@ (%d) <no data>", type: .debug, httpStatusCodeDescription, httpStatusCode)
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
            
            os_log("Error message received: %@", type: .debug, errorMessage)
            
            switch httpStatusCode {
            case 401:
                throw WaniKaniAPIError.invalidAPIKey
            case 429:
                throw WaniKaniAPIError.tooManyRequests
            default:
                throw WaniKaniAPIError.unknownError(httpStatusCode: httpStatusCode, message: errorMessage)
            }
        default:
            throw WaniKaniAPIError.unhandledStatusCode(httpStatusCode: httpStatusCode, data: data)
        }
    }
    
    private func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(apiRevision, forHTTPHeaderField: "Wanikani-Revision")
        
        os_log("Initiating request for %@", type: .debug, url.absoluteString)
        
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
                        os_log("Ignoring duplicate state change for task with identifier %d triggering network activity start", type: .debug, task.taskIdentifier)
                        return
                    }
                    os_log("Task with identifier %d triggering network activity start", type: .debug, task.taskIdentifier)
                    networkActivityDelegate.networkActivityDidStart()
                    running = true
                case .suspended:
                    guard running else {
                        os_log("Ignoring duplicate state change for task with identifier %d triggering network activity finish", type: .debug, task.taskIdentifier)
                        return
                    }
                    os_log("Task with identifier %d triggering network activity finish", type: .debug, task.taskIdentifier)
                    networkActivityDelegate.networkActivityDidFinish()
                    running = false
                case .canceling, .completed:
                    guard running else {
                        os_log("Ignoring duplicate state change for task with identifier %d triggering network activity finish (terminal state)", type: .debug, task.taskIdentifier)
                        return
                    }
                    os_log("Task with identifier %d triggering network activity finish (terminal state)", type: .debug, task.taskIdentifier)
                    guard running else { return }
                    networkActivityDelegate.networkActivityDidFinish()
                    running = false
                    observer.invalidate()
                @unknown default: break
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
