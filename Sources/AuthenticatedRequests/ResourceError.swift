//
//  ResourceError.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/// An error that could occurr while trying to get a resource.
public enum ResourceError: Error, LocalizedError {
    
    case badResponse(responseCode: Int, message: String?)
    case notHttpResponse
    case badURL
    case badDataType
    
    public var localizedDescription: String {
        switch self {
        case .badResponse(let responseCode, let message):
            var base = "Received an error response from the server\n[error code: \(responseCode)"
            if let message {
                base += " " + message
            }
            base += "]"
            return base
        case .notHttpResponse:
            return "Received a non HTTP response."
        case .badURL:
            return "The url cannot be built."
        case .badDataType:
            return "Unknown data type."
        }
    }
    
    public var errorDescription: String? {
        localizedDescription
    }
    
    public var errcode: Int? {
        
        guard case let .badResponse(responseCode, _) = self else {
            return nil
        }
        return responseCode
    }
}
