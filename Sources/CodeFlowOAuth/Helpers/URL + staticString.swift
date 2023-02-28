//
//  URL + staticString.swift
//  
//
//  Created by Francesco Bianco on 27/02/23.
//

import Foundation

extension URL {
    
    init(staticString string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid static URL string: \(string)")
        }

        self = url
    }
}
