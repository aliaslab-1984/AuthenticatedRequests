//
//  OAuthFlow.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation

/**
 Specifies all the requirements for obtaining the authentication token from an OAuth-Based service.
 */
public protocol OAuthFlow {
    
    var clientID: String { get }
    var queryParameters: [String: String]? { get }
    var httpBody: Data? { get }
    
    var isValid: Bool { get }
    
    func isEqualTo(otherFlow: OAuthFlow?) -> Bool
}
