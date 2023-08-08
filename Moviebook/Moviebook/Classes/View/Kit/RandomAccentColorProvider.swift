//
//  RandomAccentColorProvider.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/08/2023.
//

import SwiftUI

final class RandomAccentColorProvider: ObservableObject {

    private static let allColors: Set<Color> = [
        .accentColor,
        .secondaryAccentColor,
        .tertiaryAccentColor
    ]

    private var colors: Set<Color>

    init() {
        colors = Self.allColors
    }

    func nextColor() -> Color {
        guard let color = colors.randomElement() else {
            colors = Self.allColors
            return colors.remove(at: colors.startIndex)
        }

        colors.remove(color)
        return color
    }
}
