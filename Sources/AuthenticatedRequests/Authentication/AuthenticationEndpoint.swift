//
//  AuthenticationEndpoint.swift
//
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

/**
 This enum encapsulates all the requests that must be sent to retrieve or refresh an access token.
 */
public struct AuthenticationEndpoint: Resource {
    
    public typealias Input = ARClientCredentials
    
    public typealias Output = OAuth2Token
    
    let baseEndpoint: URL
    
    private let newTokenPath: String
    
    init(baseEndpoint: URL,
         path: String) {
        self.baseEndpoint = baseEndpoint
        self.newTokenPath = path
    }
    
    public var httpMethod: HttpMethod {
        return .post
    }
    
    public func urlRequest(using parameter: Input) throws -> URLRequest {
        let completeEndpoint = self.baseEndpoint.appendingPathComponent(self.newTokenPath)
        
        var urlRequest = URLRequest(url: completeEndpoint)
        urlRequest.httpMethod = self.httpMethod.rawValue
        urlRequest.setValue("application/x-www-form-urlencoded",
                            forHTTPHeaderField: "Content-Type")
        
        let loginData: [String: String] = ["grant_type": "client_credentials",
                                           "client_id": parameter.clientID,
                                           "client_secret": parameter.clientSecret]
        
        urlRequest.httpBody = loginData.urlEncoded
        
        return urlRequest
    }
    
}

extension Dictionary where Value == String, Key == String {
    
    var urlEncoded: Data? {
        return self.compactMap { touple in
            return "\(touple.key)=\(touple.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? touple.value)"
        }.joined(separator: "&").data(using: .utf8)
    }
    
}
