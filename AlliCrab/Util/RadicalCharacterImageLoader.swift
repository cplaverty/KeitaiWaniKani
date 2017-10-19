//
//  RadicalCharacterImageLoader.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation
import os
import UIKit
import WaniKaniKit

enum RadicalCharacterImageLoaderError: Error {
    case noRenderableImages
}

class RadicalCharacterImageLoader {
    private static let parentDirectory: URL = {
        let fileManager = FileManager.default
        let cachesDir = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let parentDirectory = cachesDir.appendingPathComponent("RadicalImages", isDirectory: true)
        if !fileManager.fileExists(atPath: parentDirectory.path) {
            try! fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return parentDirectory
    }()
    
    let characterImage: SubjectImage?
    private var task: URLSessionDownloadTask?
    
    init(characterImages: [SubjectImage]) {
        self.characterImage = characterImages.first(where: { image in image.contentType == "image/png" })
    }
    
    deinit {
        task?.cancel()
    }
    
    func loadImage(completionHandler: @escaping (UIImage?, Error?) -> Void) {
        guard let image = characterImage else {
            completionHandler(nil, RadicalCharacterImageLoaderError.noRenderableImages)
            return
        }
        
        let url = image.url
        let destination = RadicalCharacterImageLoader.parentDirectory.appendingPathComponent(url.lastPathComponent)
        
        guard !FileManager.default.fileExists(atPath: destination.path) else {
            let image = makeUIImage(contentsOfFile: destination.path)
            completionHandler(image, nil)
            return
        }
        
        if #available(iOS 10, *) {
            os_log("Downloading radical image at %@", type: .debug, url as NSURL)
        }
        let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            DispatchQueue.main.sync {
                NetworkIndicatorController.shared.networkActivityDidFinish()
                self.task = nil
                
                guard let location = location else {
                    if #available(iOS 10, *) {
                        os_log("Download failed: %@", type: .error, error?.localizedDescription ?? "<no error>")
                    }
                    completionHandler(nil, error)
                    return
                }
                
                let fileManager = FileManager.default
                try? fileManager.removeItem(at: destination)
                
                do {
                    if #available(iOS 10, *) {
                        os_log("Caching radical image to %@", type: .debug, destination.path)
                    }
                    try fileManager.moveItem(at: location, to: destination)
                    let image = self.makeUIImage(contentsOfFile: destination.path)
                    completionHandler(image, nil)
                } catch {
                    completionHandler(nil, error)
                }
            }
        }
        
        self.task = task
        
        NetworkIndicatorController.shared.networkActivityDidStart()
        task.resume()
    }
    
    private func makeUIImage(contentsOfFile path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)?.withRenderingMode(.alwaysTemplate)
    }
}
