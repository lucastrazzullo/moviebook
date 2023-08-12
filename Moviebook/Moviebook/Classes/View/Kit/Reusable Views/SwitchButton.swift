//
//  SwitchButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/08/2023.
//

import SwiftUI

struct SwitchButtonModifier: ViewModifier {

    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? .black : .primary)
            .background(Color.secondaryAccentColor.opacity(isSelected ? 1 : 0))
            .background(.thinMaterial)
            .cornerRadius(12)
    }
}

extension View {

    func switchButtonStyled(isSelected: Bool) -> some View {
        self.modifier(SwitchButtonModifier(isSelected: isSelected))
    }
}

struct SwitchButton: View {

    @Binding var isSelected: Bool

    let label: String

    var body: some View {
        Button { isSelected.toggle() } label: {
            Text(label)
                .modifier(
                    SwitchButtonModifier(isSelected: isSelected)
                )
        }
    }
}

struct SwitchButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SwitchButton(isSelected: .constant(true), label: "Selected")
            SwitchButton(isSelected: .constant(false), label: "Not selected")
        }
    }
}
