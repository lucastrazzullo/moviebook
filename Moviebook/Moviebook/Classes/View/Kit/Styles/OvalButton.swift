//
//  OvalButtonStyle.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/06/2023.
//

import Foundation
import SwiftUI

struct OvalButtonStyle: ButtonStyle {

    let style: OvalViewModifier.Style

    private var fixedSize: Bool {
        switch style {
        case .prominent:
            return false
        case .prominentSmall:
            return false
        case .normal:
            return true
        case .small:
            return true
        }
    }

    init(_ style: OvalViewModifier.Style = .prominent) {
        self.style = style
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .ovalStyle(style)
            .fixedSize(horizontal: fixedSize, vertical: fixedSize)
    }
}

struct OvalButtonStyle_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(.prominent))

            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(.prominentSmall))

            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(.normal))

            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(.small))
        }
        .padding()
    }
}
