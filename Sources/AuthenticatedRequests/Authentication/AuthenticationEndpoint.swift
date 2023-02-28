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
public struct AuthenticationEndpoint: Resource, Equatable {
    
    public typealias Input = OAuthFlow
    
    public typealias Output = OAuth2Token
    
    let baseEndpoint: URL
    
    private let newTokenPath: String
    
    private let userAgent: String?
    
    public init(baseEndpoint: URL,
                path: String,
                userAgent: String? = nil) {
        self.baseEndpoint = baseEndpoint
        self.newTokenPath = path
        self.userAgent = userAgent
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
        
        if let userAgent {
            urlRequest.setValue(userAgent,
                                forHTTPHeaderField: "User-Agent")
        }
        
        urlRequest.httpBody = parameter.httpBody
        
        return urlRequest
    }
    
}

public extension Dictionary where Value == String, Key == String {
    
    var urlEncoded: Data? {
        return self.compactMap { touple in
            return "\(touple.key)=\(touple.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? touple.value)"
        }.joined(separator: "&").data(using: .utf8)
    }
    
}
