//
//  String+Regex.swift
//  Vault
//
//  Created by Егор Шкарин on 16.03.2026.
//

import Foundation

public extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\.[A-Za-z]{2,}$"#
        
        return self.range(
            of: pattern,
            options: [.regularExpression]
        ) != nil
    }
}
