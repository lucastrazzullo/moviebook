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
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating.percentage*5) ? "star.fill" : "star")
                    .foregroundColor(.accentColor)
                    .font(.caption2)
            }
        }
    }
}

struct RatingView_Previews: PreviewProvider {
    static var previews: some View {
        RatingView(rating: .init(value: 4, quota: 5))
    }
}
