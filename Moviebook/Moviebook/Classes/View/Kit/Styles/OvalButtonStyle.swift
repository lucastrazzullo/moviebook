//
//  OvalButtonStyle.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/06/2023.
//

import Foundation
import SwiftUI

struct OvalButtonStyle: ButtonStyle {

    enum Prominency {
        case big
        case small

        var padding: CGFloat {
            switch self {
            case .big:
                return 22
            case .small:
                return 12
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .big:
                return 24
            case .small:
                return 16
            }
        }

        var font: Font {
            switch self {
            case .big:
                return .title3
            case .small:
                return .subheadline
            }
        }
    }

    let prominency: Prominency

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .font(prominency.font.bold())
            .foregroundColor(.white)
            .padding(prominency.padding)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: prominency.cornerRadius))
    }

    init(prominency: Prominency = .big) {
        self.prominency = prominency
    }
}

struct OvalButtonStyle_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(prominency: .big))

            Button(action: {}) {
                Text("Text")
            }
            .buttonStyle(OvalButtonStyle(prominency: .small))
        }
        .padding()
    }
}
