//
//  BasicCodeFlowConfiguration.swift
//  
//
//  Created by Francesco Bianco on 24/02/23.
//

import Foundation

public struct BasicCodeFlowConfiguration: CodeFlowConfiguration {
    
    let state: String
    let responseType: String
    
    public init(stateLenght: Int = 20) {
        self.state = CryptographicHelper.generateState(withLength: stateLenght)
        self.responseType = "code"
    }
    
    public var queryParameters: [URLQueryItem] {
        return [
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "state", value: state)
        ]
    }
}
