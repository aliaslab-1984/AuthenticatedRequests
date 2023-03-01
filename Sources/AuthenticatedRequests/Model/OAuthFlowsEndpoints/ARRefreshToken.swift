//
//  ARRefreshToken.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation

/**
 The authentication element that is required to obtain access to the
 remote service for a specific client.
 */
public struct ARRefreshToken: Codable, Equatable, OAuthFlow {
    
    public let clientID: String
    let clientSecret: String?
    let refreshToken: String
    
    /// Creates a new instance of a code-flow authentication object.
    /// - Parameters:
    ///   - clientID: The client id for the application
    ///   - code: The code that you received on the first phase of the code-flow authentication process.
    ///   - redirectUrl: The redirect uri that is provided with the app.
    ///   - codeVerifier: The code verifier generated by the first login.
    public init(clientID: String,
                clientSecret: String?,
                refreshToken: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.refreshToken = refreshToken
    }
    
    // MARK: OAuthFlow
    
    public var queryParameters: [String : String]? {
        return nil
    }
    
    public var httpBody: Data? {
        var loginData: [String: String] = ["grant_type": "refresh_token",
                                         
                                           "client_id": clientID,
                                           "refresh_token": refreshToken]
        
        if let clientSecret {
            loginData["client_secret"] = clientSecret
        }
        
        
        return loginData.urlEncoded
    }
    
    public var isValid: Bool {
        guard !clientID.isEmpty ||
              !refreshToken.isEmpty else {
            return false
        }
        
        return true
    }
    
    public func isEqualTo(otherFlow: OAuthFlow?) -> Bool {
        if let other = otherFlow as? ARRefreshToken {
            return other == self
        } else {
            return false
        }
    }
}
