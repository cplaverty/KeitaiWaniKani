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
    case loadFailed(URL)
}

class RadicalCharacterImageLoader {
    private var task: URLSessionDataTask?
    
    deinit {
        task?.cancel()
    }
    
    func loadImage(from choices: [Radical.CharacterImage], completionHandler: @escaping (Result<UIImage, Error>) -> Void) {
        guard let image = selectImage(from: choices) else {
            completionHandler(.failure(RadicalCharacterImageLoaderError.noRenderableImages))
            return
        }
        
        let url = image.url
        os_log("Downloading radical image at %@", type: .debug, url as NSURL)
        
        let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: .oneMinute)
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            self.task = nil
            
            DispatchQueue.main.async {
                if let error = error {
                    os_log("Download failed: %@", type: .error, error as NSError)
                    completionHandler(.failure(error))
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    completionHandler(.success(image))
                } else {
                    completionHandler(.failure(RadicalCharacterImageLoaderError.loadFailed(url)))
                }
            }
        }
        
        self.task = task
        
        task.resume()
    }
    
    private func selectImage(from choices: [Radical.CharacterImage]) -> Radical.CharacterImage? {
        let renderableImages = choices.filter({ $0.contentType == "image/png" })
        return renderableImages.first(where: { $0.metadata.styleName == "original" }) ?? renderableImages.first
    }
}
