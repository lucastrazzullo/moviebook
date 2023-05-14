//
//  SegmentedPicker.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 14/05/2023.
//

import SwiftUI

struct SegmentedPicker: ViewModifier {
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .onAppear {
                UISegmentedControl.appearance().backgroundColor = UIColor(Color.black.opacity(0.8))
                UISegmentedControl.appearance().selectedSegmentTintColor = .white
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            }
    }
}

extension Picker {

    func segmentedStyled() -> some View {
        modifier(SegmentedPicker())
    }
}
