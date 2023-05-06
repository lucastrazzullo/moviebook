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
        VStack {
            Text("An error occoured")
            Button(action: retry) {
                Text("Retry")
            }
        }
    }
}

struct RetriableErrorView_Previews: PreviewProvider {
    static var previews: some View {
        RetriableErrorView(retry: {})
    }
}
