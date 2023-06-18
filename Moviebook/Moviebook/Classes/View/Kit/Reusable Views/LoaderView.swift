//
//  LoaderView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI

struct LoaderView: View {

    var body: some View {
        Group {
            ProgressView()
                .controlSize(.large)
                .tint(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoaderView_Previews: PreviewProvider {
    static var previews: some View {
        LoaderView()
    }
}
