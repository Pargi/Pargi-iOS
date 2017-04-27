//
//  Networking.swift
//  Pargi
//
//  Simple wrapper around URLSession to get rid of the delegate
//  nonsense and abstract downloading a file
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation

class Downloader: NSObject, URLSessionDownloadDelegate {
    typealias CompletionHandler = (_ error: Error?, _ location: URL?) -> Void
    
    let URL: URL
    let completion: CompletionHandler
    
    private var session: URLSession!
    
    init(URL: URL, completion: @escaping CompletionHandler) {
        self.URL = URL
        self.completion = completion
        
        super.init()
        
        // Initialise the session
        let config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        // Create the task
        let task = self.session.downloadTask(with: URL)
        task.resume()
    }
    
    // MARK: URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.completion(error, nil)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.completion(nil, location)
    }
}
