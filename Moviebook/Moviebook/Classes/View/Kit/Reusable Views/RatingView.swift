//
//  RatingView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI
import MoviebookCommon

struct RatingView: View {

    let rating: Rating

    var body: some View {
        ZStack {
            stars(filled: false)
            stars(filled: true)
                .mask(
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(rating.percentage))
                    }
                )
        }
    }

    @ViewBuilder private func stars(filled: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: filled ? "star.fill" : "star")
                    .foregroundColor(.accentColor)
                    .font(.caption2)
            }
        }
    }
}

struct RatingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RatingView(rating: .init(value: 0, quota: 5))
            RatingView(rating: .init(value: 0.5, quota: 5))
            RatingView(rating: .init(value: 1, quota: 5))
            RatingView(rating: .init(value: 1.5, quota: 5))
            RatingView(rating: .init(value: 2, quota: 5))
            RatingView(rating: .init(value: 2.5, quota: 5))
            RatingView(rating: .init(value: 3, quota: 5))
            RatingView(rating: .init(value: 3.5, quota: 5))
            RatingView(rating: .init(value: 4, quota: 5))
            RatingView(rating: .init(value: 5, quota: 5))
        }
    }
}
