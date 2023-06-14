//
//  Resource.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/**
 Represents a resource that requires to be downloaded from a remote service (REST for example).
 */
public protocol Resource {
    
    /**
     The object that is used to build the request for the needed resource.
     */
    associatedtype Input
    
    /**
     The output that is expected to be returned when requesting the resource.
     */
    associatedtype Output
    
    /**
     The HTTP method that is required to retreive/consume the resource.
     */
    var httpMethod: HttpMethod { get }
    
    /// Builds the URLRequest that's necessary to obtain the desired `Output`.
    /// - Parameter parameter: The parameter that is going to be used to build the request.
    /// - Returns: The built resource request.
    func urlRequest(using parameter: Input) throws -> URLRequest
}

public extension Resource where Output: Codable {
    
    /// Requests the desired resource asynchronously.
    /// - Parameter parameter: The input parameter that is necessary to build the URLRequest.
    /// - Returns: Returns the received data decoded into the expected output type, or throws an error.
    func request(using parameter: Input,
                 urlConfiguration: URLSessionConfiguration? = nil) async throws -> Output {
        
        let request = try await urlRequest(with: parameter)
        let session = session(urlConfiguration: urlConfiguration)
        
        let (data, response): (Data, URLResponse)
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, response) = try await session.data(for: request)
        } else {
            (data, response) = try await session.data(using: request)
        }
        
        // We check if the Task got cancelled to avoid decoding data for nothing.
        try Task.checkCancellation()
        
        // We first validate the URLResponse that we received in order to check if everything went ok.
        try validateResponse(response, data: data)
        
        if Output.self == String.self {
            return (String(data: data, encoding: .utf8) ?? "") as! Self.Output // swiftlint:disable:this force_cast
        } else {
            return try JSONDecoder().decode(Output.self, from: data)
        }
    }
}

public extension Resource where Output == URL {
    
    /// Requests the desired resource asynchronously.
    /// - Parameter parameter: The input parameter that is necessary to build the URLRequest.
    /// - Returns: Returns the received data decoded into the expected output type, or throws an error.
    func download(using parameter: Input,
                  urlConfiguration: URLSessionConfiguration? = nil) async throws -> Output {
        
        let request = try await urlRequest(with: parameter)
        let session = session(urlConfiguration: urlConfiguration)
        
        let (filesystemURL, response): (URL, URLResponse)
        if #available(iOS 15.0, macOS 12.0, *) {
            (filesystemURL, response) = try await session.download(for: request)
        } else {
            (filesystemURL, response) = try await session.download(using: request)
        }
        
        // We check if the Task got cancelled to avoid decoding data for nothing.
        try Task.checkCancellation()
        
        // We first validate the URLResponse that we received in order to check if everything went ok.
        try validateResponse(response, data: nil)
        
        return filesystemURL
    }
}

private extension Resource {
    
    private func urlRequest(with parameter: Input) async throws -> URLRequest {
        
        var request = try urlRequest(using: parameter)
        
        // If the resource is also authenticated, wee need to embedd an authentication token.
        if let authenticated = self as? AuthenticatedResource {
            let token = try await authenticated.authenticator.validToken()
            request.authenticated(with: token, headerField: authenticated.authHeader)
        }
        request.debug()
        
        return request
    }
    
    private func session(urlConfiguration: URLSessionConfiguration? = nil) -> URLSession {
        
        let session: URLSession
        if let urlConfiguration {
            session = URLSession(configuration: urlConfiguration)
        } else {
            session = URLSession.shared
        }
        return session
    }
    
    /**
     Given a URLResponse, this method trows an error if the response doesn't
     match the expected requirements.
     
     
     Specifically if the URLResponse could not be casted as a HTTPURLResponse or if the status code is not in the 2xx range.
     - Parameter response: The URLResponse that needs to be inspected.
     - Parameter data: The data associated to the URLRequest. It's used to print the optional error message associated with the response code.
     */
    func validateResponse(_ response: URLResponse, data: Data?) throws {
        
        debug(response, data: data)
        
        guard let response = response as? HTTPURLResponse else {
            throw ResourceError.notHttpResponse
        }
        
        print("Status code:", response.statusCode)
        
        guard (200 ... 299) ~= response.statusCode else { // check for http errors
            let errorMessage: String?
            if let data {
                let error = try? JSONDecoder().decode(SimpleAPIError.self, from: data)
                errorMessage = error?.error
            } else {
                errorMessage = nil
            }
            
            print("Error:", errorMessage ?? "-")
            throw ResourceError.badResponse(responseCode: response.statusCode, message: errorMessage)
        }
    }
    
    func debug(_ response: URLResponse, data: Data?) {
#if DEBUG
        defer { print(String(repeating: "=", count: debugHeaderLength)) }
        
        var trail = debugHeaderLength - 15
        if trail < 2 { trail = 2 }
        
        print("== URLResponse " + String(repeating: "=", count: trail))
        print("\(response)")
        print("Raw Data:")
        if let data {
            print(String(decoding: data, as: UTF8.self))
        } else {
            print("-- Null --")
        }
#endif
    }
}
