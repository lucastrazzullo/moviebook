//
//  OvalTextFieldStyle.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/06/2023.
//

import SwiftUI

struct OvalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .padding(22)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}
