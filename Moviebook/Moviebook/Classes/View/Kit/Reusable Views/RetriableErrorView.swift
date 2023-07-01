//
//  RetriableErrorView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/05/2023.
//

import SwiftUI

struct RetriableErrorView: View {

    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("An error occoured")
                .foregroundColor(.primary)
                .font(.title2)

            Button(action: retry) {
                Text("Retry")
            }
            .buttonStyle(OvalButtonStyle(prominency: .small))
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 40)
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

struct RetriableErrorView_Previews: PreviewProvider {
    static var previews: some View {
        RetriableErrorView(retry: {})
    }
}
