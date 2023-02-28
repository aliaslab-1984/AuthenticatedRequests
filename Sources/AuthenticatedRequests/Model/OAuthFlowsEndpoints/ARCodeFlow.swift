//
//  File.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation

/**
 The authentication element that is required to obtain access to the
 remote service for a specific client.
 */
public struct ARCodeFlow: Codable, Equatable, OAuthFlow {
    
    public let clientID: String
    let code: String
    let redirectUrl: String
    let codeVerifier: String?
    
    /// Creates a new instance of a code-flow authentication object.
    /// - Parameters:
    ///   - clientID: The client id for the application
    ///   - code: The code that you received on the first phase of the code-flow authentication process.
    ///   - redirectUrl: The redirect uri that is provided with the app.
    ///   - codeVerifier: The code verifier generated by the first login.
    public init(clientID: String,
                code: String,
                redirectUrl: String,
                codeVerifier: String?) {
        self.clientID = clientID
        self.code = code
        self.redirectUrl = redirectUrl
        self.codeVerifier = codeVerifier
    }
    
    // MARK: OAuthFlow
    
    public var queryParameters: [String : String]? {
        return nil
    }
    
    public var httpBody: Data? {
        var loginData: [String: String] = ["grant_type": "authorization_code",
                                           "code": code,
                                           "redirect_uri": redirectUrl,
                                           "client_id": clientID]
        
        if let codeVerifier {
            loginData["code_verifier"] = codeVerifier
        }
        
        return loginData.urlEncoded
    }
    
    public var isValid: Bool {
        guard !clientID.isEmpty ||
              !code.isEmpty ||
              !redirectUrl.isEmpty else {
            return false
        }
        
        return true
    }
    
    public func isEqualTo(otherFlow: OAuthFlow?) -> Bool {
        if let other = otherFlow as? ARCodeFlow {
            return other == self
        } else {
            return false
        }
    }
}
