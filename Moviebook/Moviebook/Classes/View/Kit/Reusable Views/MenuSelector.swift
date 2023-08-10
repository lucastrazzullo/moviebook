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

protocol MenuSelectorItem: Hashable, Equatable {
    var label: String { get }
}

struct MenuSelector<Item: MenuSelectorItem>: View {

    @Binding var selection: Item

    let items: [Item]

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

    @ViewBuilder private func itemView(item: Item) -> some View {
        Text(item.label.uppercased())
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

    enum Item: String, CaseIterable, MenuSelectorItem {
        case item1, item2, item3

        var label: String {
            return self.rawValue
        }
    }

    @State var selection: Item = .item1

    var body: some View {
        MenuSelector(selection: $selection, items: Item.allCases)
    }
}
