//
//  RatingView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct RatingView: View {

    let rating: Rating

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating.percentage*5) ? "star.fill" : "star")
                    .foregroundColor(index <= Int(rating.percentage*5) ? .accentColor : nil)
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
