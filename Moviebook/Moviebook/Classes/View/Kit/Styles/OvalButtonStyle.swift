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
    }

    let prominency: Prominency

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .font(.title3.bold())
            .foregroundColor(.white)
            .padding(prominency.padding)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: prominency.cornerRadius))
    }

    init(prominency: Prominency = .big) {
        self.prominency = prominency
    }
}
