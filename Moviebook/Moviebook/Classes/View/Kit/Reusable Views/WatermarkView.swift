//
//  WatermarkView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import SwiftUI

struct WatermarkView<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            content()
                .frame(width: 18, height: 18, alignment: .center)
                .font(.footnote)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8, antialiased: true)
    }
}

struct WatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        WatermarkView {
            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .fixedSize(horizontal: false, vertical: false)
            }

            Menu {
                Button { } label: {
                    Label("Shelf", systemImage: "square.stack")
                }
                Button { } label: {
                    Label("List", systemImage: "list.star")
                }
            } label: {
                Image(systemName: "square.stack")
            }
        }
    }
}
