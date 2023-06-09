//
//  PKCECodeFlowConfiguration.swift
//  
//
//  Created by Francesco Bianco on 24/02/23.
//

import Foundation

public struct PKCECodeFlowConfiguration: CodeFlowConfiguration {
    
    enum PKCEConfigurationError: Error {
        case badVerifier
        case badChallenge
    }
    
    let state: String
    let responseType: String
    let codeChallenge: String
    let codeChallengeMethod: String
    public let codeChallengeVerifier: String
    
    public init(stateLenght: Int = 20) throws {
        self.state = CryptographicHelper.generateState(withLength: stateLenght)
        self.responseType = "code"
        let verifier = CryptographicHelper.generateCodeVerifier()
        guard let challenge = CryptographicHelper.generateCodeChallenge(codeVerifier: verifier) else {
            throw PKCEConfigurationError.badChallenge
        }
        
        self.codeChallengeVerifier = verifier
        self.codeChallenge = challenge
        self.codeChallengeMethod = "S256"
    }
    
    public var queryParameters: [URLQueryItem] {
        return [
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
        ]
    }
}
