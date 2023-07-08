//
//  OvalViewStyle.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/07/2023.
//

import SwiftUI

struct OvalViewModifier: ViewModifier {

    enum Style {
        case prominent
        case prominentSmall
        case prominentTiny
        case normal
        case small

        var padding: CGFloat {
            switch self {
            case .prominent:
                return 22
            case .prominentSmall:
                return 12
            case .prominentTiny:
                return 8
            case .normal:
                return 10
            case .small:
                return 8
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .prominent:
                return 24
            case .prominentSmall:
                return 16
            case .prominentTiny:
                return 12
            case .normal:
                return 16
            case .small:
                return 12
            }
        }

        var font: Font {
            switch self {
            case .prominent:
                return .title3
            case .prominentSmall:
                return .subheadline
            case .prominentTiny:
                return .subheadline
            case .normal:
                return .footnote
            case .small:
                return .caption
            }
        }

        var background: Color {
            switch self {
            case .prominent, .prominentSmall, .prominentTiny:
                return Color.accentColor
            case .normal:
                return Color.black.opacity(0.8)
            case .small:
                return Color.black.opacity(0.6)
            }
        }
    }

    let style: Style

    func body(content: Content) -> some View {
        content
            .font(style.font.bold())
            .foregroundColor(.white)
            .padding(style.padding)
            .background(style.background, in: RoundedRectangle(cornerRadius: style.cornerRadius))
    }
}

extension View {

    func ovalStyle(_ style: OvalViewModifier.Style) -> some View {
        self.modifier(OvalViewModifier(style: style))
    }
}

struct OvalViewStyle_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            Image(systemName: "arrow.up.and.down.text.horizontal")
                .ovalStyle(.prominent)

            Image(systemName: "arrow.up.and.down.text.horizontal")
                .ovalStyle(.prominentSmall)

            Image(systemName: "arrow.up.and.down.text.horizontal")
                .ovalStyle(.normal)

            Image(systemName: "arrow.up.and.down.text.horizontal")
                .ovalStyle(.small)
        }
    }
}
