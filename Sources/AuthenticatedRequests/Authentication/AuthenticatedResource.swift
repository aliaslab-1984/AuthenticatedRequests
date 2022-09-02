//
//  AuthenticatedResource.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/**
 Describes a resource that needs an authenticator in order to be requested.
 Specifically, all the objects that conform to this protocol, require an authenticated token in order to be perfomed successfully.
 */
public protocol AuthenticatedResource {
    
    /**
     In order to make an authenticated request, is required to have an authenticator that provides a valid token that will be embedded on the HTTP request.
     */
    var authenticator: AnyAuthenticator<ARClientCredentials> { get }
    
}

extension URLRequest {
    
    /// As the name says, it makes an URLRequest authenticated, by applying the `access_token` string and the `token_type` on the *Authorization* header field.
    /// - Parameter token: The token that is going to be used to authenticate the request.
    mutating func authenticated(with token: OAuth2Token) {
        setValue(token.token_type + " " + token.access_token, forHTTPHeaderField: "Authorization")
    }
}
