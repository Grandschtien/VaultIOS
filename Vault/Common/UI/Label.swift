//
//  Label.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import UIKit

final class Label: UILabel {
    func apply(_ viewModel: LabelViewModel) {
        text = viewModel.text
        font = viewModel.font
        textColor = viewModel.textColor
        textAlignment = viewModel.alignment
        numberOfLines = viewModel.numberOfLines
        lineBreakMode = viewModel.lineBreakMode
    }
}

extension Label {
    struct LabelViewModel: Equatable {
        let text: String
        let font: UIFont
        let textColor: UIColor
        let alignment: NSTextAlignment
        let numberOfLines: Int
        let lineBreakMode: NSLineBreakMode
        
        init(
            text: String = "",
            font: UIFont = Typography.regular16,
            textColor: UIColor = .textAndIconPrimary,
            alignment: NSTextAlignment = .left,
            numberOfLines: Int = 1,
            lineBreakMode: NSLineBreakMode = .byWordWrapping
        ) {
            self.text = text
            self.font = font
            self.textColor = textColor
            self.alignment = alignment
            self.numberOfLines = numberOfLines
            self.lineBreakMode = lineBreakMode
        }
    }
}
