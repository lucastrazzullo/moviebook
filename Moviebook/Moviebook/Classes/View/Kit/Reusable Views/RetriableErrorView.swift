//
//  RetriableErrorView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/05/2023.
//

import SwiftUI
import MoviebookCommon

struct RetriableErrorView: View {

    let error: WebServiceError

    var body: some View {
        VStack(spacing: 12) {
            Text("An error occoured")
                .foregroundColor(.primary)
                .font(.title2)

            Button(action: error.retry) {
                Text("Retry")
            }
            .buttonStyle(OvalButtonStyle(.prominentSmall))
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

    enum MockError: Error {
        case someError
    }

    static var previews: some View {
        RetriableErrorView(error: .failedToLoad(error: MockError.someError, retry: {}))
    }
}
