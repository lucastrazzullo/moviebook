//
//  MenuSelector.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 10/08/2023.
//

import SwiftUI

private extension HorizontalAlignment {

    struct SelectorAlignment: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[HorizontalAlignment.leading]
        }
    }

    static let selectedItem = HorizontalAlignment(SelectorAlignment.self)
}

struct MenuSelector: View {

    @Binding var selection: String

    let items: [String]

    var body: some View {
        VStack(alignment: .selectedItem, spacing: 4) {
            HStack(spacing: 12) {
                ForEach(items, id: \.self) { item in
                    Button { selection = item } label: {
                        if item == selection {
                            itemView(item: item)
                                .alignmentGuide(.selectedItem) { d in d[HorizontalAlignment.leading] }
                        } else {
                            itemView(item: item)
                        }
                    }
                }
            }
            .font(.heroCallout)

            Capsule(style: .continuous)
                .fill(Color.secondaryAccentColor)
                .frame(width: 28, height: 4)
                .alignmentGuide(.selectedItem) { d in d[HorizontalAlignment.leading] }
        }
        .animation(.easeInOut, value: selection)
    }

    @ViewBuilder private func itemView(item: String) -> some View {
        Text(item.uppercased())
            .font(.heroCallout)
            .foregroundColor(selection == item ? .primary : .secondary)
    }
}

struct MenuSelector_Previews: PreviewProvider {

    static var previews: some View {
        MenuSelectorPreview()
    }
}

struct MenuSelectorPreview: View {

    @State var selection: String = "Item 1"

    let items: [String] = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        MenuSelector(selection: $selection, items: items)
    }
}
