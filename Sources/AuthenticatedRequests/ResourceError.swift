//
//  ResourceError.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/// An error that could occurr while trying to get a resource.
public enum ResourceError: Error {
    
    case badResponse(responseCode: Int)
    case notHttpResponse
    case badURL
    
    public var localizedDescription: String {
        switch self {
        case .badResponse(let responseCode):
            return "Received an error response from the server: error code \(responseCode)"
        case .notHttpResponse:
            return "Received a non HTTP response."
        case .badURL:
            return "The url cannot be built."
        }
    }
}
