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
    func request(using parameter: Input) async throws -> Output {
        var request = try urlRequest(using: parameter)
            
        // If the resource is also authenticated, wee need to embedd an authentication token.
        if let authenticated = self as? AuthenticatedResource {
            let token = try await authenticated.authenticator.validToken()
            request.authenticated(with: token)
        }
        
        let (data, response): (Data, URLResponse)
        if #available(iOS 15.0, macOS 12.0, *) {
            (data, response) = try await URLSession.shared.data(for: request)
        } else {
            (data, response) = try await URLSession.shared.data(using: request)
        }
        
        // We check if the Task got cancelled to avoid decoding data for nothing.
        try Task.checkCancellation()
        
        // We first validate the URLResponse that we received in order to check if everything went ok.
        try validateResponse(response)
        
        if Output.self == String.self {
            return (String(data: data, encoding: .utf8) ?? "") as! Self.Output // swiftlint:disable:this force_cast
        } else {
            return try JSONDecoder().decode(Output.self, from: data)
        }
        
    }
    
}

extension Resource {
    
    /**
     Given a URLResponse, this method trows an error if the response doesn't
     match the expected requirements.
     
     
     Specifically if the URLResponse could not be casted as a HTTPURLResponse or if the status code is not in the 2xx range.
     - Parameter response: The URLResponse that needs to be inspected.
     */
    func validateResponse(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw ResourceError.notHttpResponse
        }
        
        print("Status code: ", response.statusCode)
        
        guard (200 ... 299) ~= response.statusCode else { // check for http errors
            throw ResourceError.badResponse(responseCode: response.statusCode)
        }
    }
}
