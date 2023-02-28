//
//  AuthenticationConfiguration.swift
//  
//
//  Created by Francesco Bianco on 24/02/23.
//

import Foundation

public struct AuthenticationConfiguration {
    
    public let baseURL: URL
    public let clientId: String
    public let redirectURI: String
    public let scope: String
    public let codeFlowConfiguration: any CodeFlowConfiguration
    
    public init(baseURL: URL,
                clientId: String,
                redirectURI: String,
                scope: String,
                codeFlowConfiguration: some CodeFlowConfiguration) {
        self.baseURL = baseURL
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scope = scope
        self.codeFlowConfiguration = codeFlowConfiguration
    }
    
    var queryItems: [URLQueryItem] {
        return [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scope)
        ]
    }
}
