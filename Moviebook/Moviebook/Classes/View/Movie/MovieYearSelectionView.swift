//
//  MovieYearSelectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/08/2023.
//

import SwiftUI

struct MovieYearSelectionView: View {

    @Binding var selection: Int?

    let years: [Int]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(explodedYears, id: \.self) { year in
                YearSwitch(selection: $selection, year: year)
                Spacer()
            }

            YearPicker(selection: $selection, range: yearsInPicker)
        }
        .padding(.horizontal)
        .animation(nil, value: selection)
    }

    private var explodedYears: [Int] {
        return years.cap(bottom: years.count - 4)
            .reversed()
    }

    private var yearsInPicker: [Int?] {
        return (years.cap(top: years.count - 4) + [nil])
            .reversed()
    }
}

private struct YearSwitch: View {

    @Binding var selection: Int?

    let year: Int

    var body: some View {
        SwitchButton(
            isSelected: Binding(
                get: { selection == year },
                set: { isSelected in selection = isSelected ? year : nil }
            ),
            label: "\(year)"
        )
    }
}

private struct YearPicker: View {

    @Binding var selection: Int?

    let range: [Int?]

    var body: some View {
        Menu {
            ForEach(range, id: \.self) { year in
                Button { selection = year } label: {
                    Text(label(year: year))
                    if year == selection {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack {
                Text(label(year: selection))
                Image(systemName: "chevron.down")
            }
            .fixedSize()
            .switchButtonStyled(isSelected: selection != nil && range.contains(selection))
        }
    }

    private func label(year: Int?) -> String {
        if let year, range.contains(year) {
            return "\(year)"
        } else {
            return "All"
        }
    }
}

struct MovieYearSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MovieYearSelectionView(selection: .constant(nil), years: Array(2000...2020))
    }
}
