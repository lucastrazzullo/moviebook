//
//  CircularRatingView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/10/2022.
//

import SwiftUI

struct CircularRatingView: View {

    static let ratingQuota: CGFloat = 10

    enum Style {
        case small
        case prominent
    }

    let rating: CGFloat
    let label: String?
    let style: Style

    var body: some View {
        ZStack {
            Circle()
                .stroke(style: .init(lineWidth: strokeWidth, lineCap: .round))
                .foregroundColor(.white.opacity(0.2))

            Circle()
                .trim(from: 0.0, to: rating / Self.ratingQuota)
                .stroke(style: .init(lineWidth: strokeWidth, lineCap: .round))

            VStack {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(rating, format: .number).font(ratingFont)
                    Text("/").font(ratingBaseFont)
                    Text("10").font(ratingBaseFont)
                }
                .animation(nil, value: rating)

                if let label = label {
                    Text(label)
                        .font(labelFont)
                        .opacity(0.8)
                }
            }
        }
    }

    private var ratingFont: Font {
        switch style {
        case .small:
            return .subheadline
        case .prominent:
            return .title
        }
    }

    private var ratingBaseFont: Font {
        switch style {
        case .small:
            return .caption2
        case .prominent:
            return .body
        }
    }

    private var labelFont: Font {
        switch style {
        case .small:
            return .caption2
        case .prominent:
            return .footnote
        }
    }

    private var strokeWidth: CGFloat {
        switch style {
        case .small:
            return 4
        case .prominent:
            return 12
        }
    }
}

struct CircularRatingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CircularRatingView(rating: 2.6, label: "Label", style: .prominent)
            CircularRatingView(rating: 7, label: "Label", style: .small)
        }
    }
}
