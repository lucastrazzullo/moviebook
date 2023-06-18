//
//  OvalButtonStyle.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/06/2023.
//

import Foundation
import SwiftUI

struct OvalButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundColor(.white)
            .padding(22)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 24))
    }
}
