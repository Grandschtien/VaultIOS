//
//  ImageProvider.swift
//  Vault
//
//  Created by Egor Shkarin on 31.03.2026.
//

import UIKit

protocol ImageProviding {
    var houseImage: UIImage? { get }
    var houseFillImage: UIImage? { get }
    var chartPieImage: UIImage? { get }
    var chartPieFillImage: UIImage? { get }
    var trashImage: UIImage? { get }
    var envelopeImage: UIImage? { get }
    var lockImage: UIImage? { get }
    var lockRotationImage: UIImage? { get }
    var personImage: UIImage? { get }
    var magnifyingglassImage: UIImage? { get }
    var checkmarkCircleFillImage: UIImage? { get }
    var circleImage: UIImage? { get }

    func personCropCircleImage(pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage?
    func plusImage(pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage?
}

extension ImageProviding {
    var houseImage: UIImage? { UIImage(systemName: "house") }
    var houseFillImage: UIImage? { UIImage(systemName: "house.fill") }
    var chartPieImage: UIImage? { UIImage(systemName: "chart.pie") }
    var chartPieFillImage: UIImage? { UIImage(systemName: "chart.pie.fill") }
    var trashImage: UIImage? { Asset.Icons.trash.image }
    var envelopeImage: UIImage? { UIImage(systemName: "envelope") }
    var lockImage: UIImage? { UIImage(systemName: "lock") }
    var lockRotationImage: UIImage? { UIImage(systemName: "lock.rotation") }
    var personImage: UIImage? { UIImage(systemName: "person") }
    var magnifyingglassImage: UIImage? { UIImage(systemName: "magnifyingglass") }
    var checkmarkCircleFillImage: UIImage? { UIImage(systemName: "checkmark.circle.fill") }
    var circleImage: UIImage? { UIImage(systemName: "circle") }

    func personCropCircleImage(pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage? {
        UIImage(
            systemName: "person.crop.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        )
    }

    func plusImage(pointSize: CGFloat, weight: UIImage.SymbolWeight) -> UIImage? {
        UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        )
    }
}
