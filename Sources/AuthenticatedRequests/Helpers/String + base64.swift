//
//  File.swift
//  
//
//  Created by Francesco Bianco on 22/06/22.
//

import Foundation

extension String {
    
    var fromBase64: String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    var base64: String {
        return Data(self.utf8).base64EncodedString()
    }
}
