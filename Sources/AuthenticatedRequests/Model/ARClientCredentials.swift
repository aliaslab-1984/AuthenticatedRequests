//
//  File.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/**
 The authentication element that is required to obtain access to the 
 remote service for a specific client.
 */
public struct ARClientCredentials: Codable, Equatable {
    
    let clientID: String
    let clientSecret: String
    let scope: [String]
    
    /// Creates a new instance of a client credentials object.
    /// - Parameters:
    ///   - clientID: The client id.
    ///   - clientSecret: The client secret associated with the client id
    ///   - scope: The scope that is necessary to access.
    public init(clientID: String,
                clientSecret: String,
                scope: Set<String>) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.scope = Array(scope)
    }
}
