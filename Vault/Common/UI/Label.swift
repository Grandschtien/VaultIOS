//
//  Label.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import UIKit

final class Label: UILabel {
    private(set) var viewModel: LabelViewModel

    init(viewModel: LabelViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        apply(viewModel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: LabelViewModel) {
        self.viewModel = viewModel
        text = viewModel.text
        font = viewModel.font
        textColor = viewModel.textColor
        textAlignment = viewModel.alignment
        numberOfLines = viewModel.numberOfLines
        lineBreakMode = viewModel.lineBreakMode
    }
}

extension Label {
    struct LabelViewModel {
        let text: String
        let font: UIFont
        let textColor: UIColor
        let alignment: NSTextAlignment
        let numberOfLines: Int
        let lineBreakMode: NSLineBreakMode
    }
}
