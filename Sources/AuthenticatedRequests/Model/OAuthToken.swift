//
//  OAuthToken.swift
//
//  Created by Francesco Bianco on 12/08/2019.
//  Copyright © 2019 Francesco Bianco. All rights reserved.
//

import Foundation

public protocol BearerToken: Codable, Equatable {
    
    /// checks if token is still valid or has expired
    var isValid: Bool { get }
}

public struct OAuth2Token: BearerToken, Sendable {
    
    /// date when the token was initialized
    public var date = Date()
    public var access_token: String // swiftlint:disable:this identifier_name
    public var refresh_token: String? // swiftlint:disable:this identifier_name
    public var expires_in: Int // swiftlint:disable:this identifier_name
    public var token_type: String // swiftlint:disable:this identifier_name
    public var scope: String?
    
    /// checks if token is still valid or has expired
    public var isValid: Bool {
        let now = Date()
        let seconds = TimeInterval(expires_in)
        return now.timeIntervalSince(date) < seconds
    }
    
    enum TokenCodingKeys: String, CodingKey {

        case access_token // swiftlint:disable:this identifier_name
        case refresh_token // swiftlint:disable:this identifier_name
        case expires_in // swiftlint:disable:this identifier_name
        case token_type // swiftlint:disable:this identifier_name
        case scope
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TokenCodingKeys.self)
        access_token = try container.decode(String.self, forKey: .access_token)
        refresh_token = try? container.decode(String.self, forKey: .refresh_token)
        expires_in = try container.decode(Int.self, forKey: .expires_in)
        token_type = try container.decode(String.self, forKey: .token_type)
        scope = try? container.decodeIfPresent(String.self, forKey: .scope) ?? nil
        date = Date()
    }
    
    // swiftlint:disable identifier_name
    public init(access_token: String,
                refresh_token: String?,
                expires_in: Int,
                token_type: String,
                scope: String? = nil,
                creationDate: Date = Date()) {
        // swiftlint:enable identifier_name
        
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.token_type = token_type
        self.expires_in = expires_in
        self.date = creationDate
        self.scope = scope
    }
}

extension OAuth2Token {
    
    /// An invalid token, with all the fields blank and an expiry time interval of 0.
    public static let invalidToken = OAuth2Token(access_token: "",
                                                 refresh_token: nil,
                                                 expires_in: 0,
                                                 token_type: "",
                                                 creationDate: Date())
    
    public static let empty = OAuth2Token(access_token: "",
                                          refresh_token: nil,
                                          expires_in: 0,
                                          token_type: "bearer")
}

