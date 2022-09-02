//
//  File.swift
//  
//
//  Created by Francesco Bianco on 21/07/22.
//

import Foundation

public extension String {
    
    var validPublicKey: String {
        return self
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
    
}
