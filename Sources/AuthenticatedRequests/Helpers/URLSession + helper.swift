/**
*  AsyncCompatibilityKit
*  Copyright (c) John Sundell 2021
*  MIT license, see LICENSE.md file for details
*/

import Foundation

@available(iOS, deprecated: 15.0, message: "AsyncCompatibilityKit is only useful when targeting iOS versions earlier than 15")
@available(macOS, deprecated: 12.0, message: "AsyncCompatibilityKit is only useful when targeting iOS versions earlier than 15")
public extension URLSession {
    /// Start a data task with a URL using async/await.
    /// - parameter url: The URL to send a request to.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(using: URLRequest(url: url))
    }

    /// Start a data task with a `URLRequest` using async/await.
    /// - parameter request: The `URLRequest` that the data task should perform.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    func data(using request: URLRequest) async throws -> (Data, URLResponse) {
        var dataTask: URLSessionDataTask?
        let onCancel = { dataTask?.cancel() }

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    dataTask = self.dataTask(with: request) { data, response, error in
                        guard let data = data, let response = response else {
                            let error = error ?? URLError(.badServerResponse)
                            return continuation.resume(throwing: error)
                        }

                        continuation.resume(returning: (data, response))
                    }

                    dataTask?.resume()
                }
            },
            onCancel: {
                onCancel()
            }
        )
    }
    
    /// Start a download task with a URL using async/await.
    /// - parameter url: The URL to send a request to.
    /// - returns: A tuple containing the filesystem `URL` where the content was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the download task.
    func download(from url: URL) async throws -> (URL, URLResponse) {
        try await download(using: URLRequest(url: url))
    }

    /// Start a download task with a `URLRequest` using async/await.
    /// - parameter request: The `URLRequest` that the data task should perform.
    /// - returns: A tuple containing the filesystem `URL` where the content was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the download task.
    func download(using request: URLRequest) async throws -> (URL, URLResponse) {
        var dataTask: URLSessionDownloadTask?
        let onCancel = { dataTask?.cancel() }

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    
                    dataTask = self.downloadTask(with: request) { filesystemURL, response, error in
                        guard let url = filesystemURL,
                              let response = response else {
                            let error = error ?? URLError(.badServerResponse)
                            return continuation.resume(throwing: error)
                        }
                        
                        do {
                            
                            let cache = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            
                            let destinationFolder = cache.appendingPathComponent("Downloads", isDirectory: true)
                                
                            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
                            
                            let destinationURL = destinationFolder.appendingPathComponent(url.lastPathComponent)
                            
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            
                            continuation.resume(returning: (destinationURL, response))
                        } catch {
                            continuation.resume(returning: (url, response))
                        }
                    }
                    
                    dataTask?.resume()
                }
            },
            onCancel: {
                onCancel()
            }
        )
    }
}
