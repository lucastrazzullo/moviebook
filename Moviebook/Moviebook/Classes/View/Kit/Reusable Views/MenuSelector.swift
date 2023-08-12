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

protocol MenuSelectorItem: Identifiable {
    var label: String { get }
    var badge: Int { get }
}

struct MenuSelector<Item: MenuSelectorItem>: View {

    @Binding var selection: Item

    let items: [Item]

    var body: some View {
        VStack(alignment: .selectedItem, spacing: 4) {
            HStack(spacing: 12) {
                ForEach(items, id: \.id) { item in
                    Button { selection = item } label: {
                        if item.id == selection.id {
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
        .animation(.easeInOut, value: selection.id)
    }

    @ViewBuilder private func itemView(item: Item) -> some View {
        ZStack(alignment: .topLeading) {
            Text(item.label.uppercased())
                .font(.heroCallout)
                .foregroundColor(selection.id == item.id ? .primary : .secondary)

            if item.badge > 0 {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .padding(2)
                    .background(.white, in: Circle())
                    .offset(x: -6, y: -6)
            }
        }
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

        var id: String {
            return self.rawValue
        }

        var label: String {
            return self.rawValue
        }

        var badge: Int {
            return 1
        }
    }

    @State var selection: Item = .item1

    var body: some View {
        MenuSelector(selection: $selection, items: Item.allCases)
    }
}
