//
//  PillView.swift
//  Vault
//
//  Created by Егор Шкарин on 12.03.2026.
//

import UIKit
import SnapKit

final class PillView: UIView, LayoutScaleProviding {
    private let icon = UIImageView()
    private let text = Label()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(viewModel: ViewModel) {
        text.apply(viewModel.text)
        icon.image = viewModel.image
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}

// MARK: Private
private extension PillView {
    func setupView() {
        addSubview(stackView)
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(text)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(spaceXS)
        }
        
        stackView.axis = .horizontal
        stackView.spacing = spaceXXS
        
        icon.image = Asset.Icons.aiUsageLight.image
        
        backgroundColor = ColorAsset.Color.aiUsage
    }
}

// MARK: ViewModel
extension PillView {
    struct ViewModel: Equatable {
        let text: Label.LabelViewModel
        let image: UIImage
        
        init(
            text: Label.LabelViewModel = .init(),
            image: UIImage = UIImage()
        ) {
            self.text = text
            self.image = image
        }
    }
}
