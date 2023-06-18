//
//  ExpandibleOverviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/04/2023.
//

import SwiftUI

struct ExpandibleOverviewView: View {

    @Binding var isExpanded: Bool

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.title2)

            Text(overview)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { isExpanded.toggle() }) {
                Text(isExpanded ? "Less" : "More")
            }
        }
        .padding(.horizontal)
    }
}

struct ExpandibleOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        ExpandibleOverviewView(isExpanded: .constant(true), overview: "Overview text")
    }
}
