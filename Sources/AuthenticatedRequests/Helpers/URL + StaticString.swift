//
//  File.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

public extension URL {
    
    init(staticString string: StaticString) {
        
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid static URL string: \(string)")
        }

        self = url
    }
}
