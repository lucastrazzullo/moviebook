//
//  SpecsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/04/2023.
//

import SwiftUI

struct SpecsView: View {

    enum Item: Hashable {
        case date(_ date: Date, label: String)
        case currency(_ value: Int, code: String, label: String)
        case duration(_ duration: TimeInterval, label: String)
        case list(_ elements: [String], label: String)
    }

    private enum DisplayedItem: Hashable {
        case divider
        case item(Item)
    }

    private let title: String
    private let items: [DisplayedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2)
                .padding(.leading)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    switch item {
                    case .divider:
                        Divider()
                    case .item(let item):
                        switch item {
                        case .date(let date, let label):
                            SpecsRow(label: label) {
                                Group {
                                    if date > Date.now {
                                        HStack(spacing: 4) {
                                            Text("Coming on")
                                            Text(date, style: .date).bold()
                                        }
                                        .padding(4)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(.yellow))
                                    } else {
                                        Text(date, style: .date)
                                    }
                                }
                            }
                        case .currency(let value, let code, let label):
                            SpecsRow(label: label) {
                                Text(value, format: .currency(code: code))
                            }
                        case .duration(let duration, let label):
                            SpecsRow(label: label) {
                                Text(Duration.seconds(duration).formatted(.time(pattern: .hourMinute)))
                            }
                        case .list(let elements, let label):
                            SpecsRow(label: label) {
                                VStack(alignment: .trailing) {
                                    ForEach(elements, id: \.self) { element in
                                        Text(element)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .font(.subheadline)
            .padding()
        }
    }

    init(title: String, items: [Item]) {
        self.title = title
        self.items = items.enumerated()
            .reduce([DisplayedItem]()) { list, item in
                var list = list
                if item.offset > 0 {
                    list.append(.divider)
                }
                list.append(.item(item.element))
                return list
            }
    }
}

private struct SpecsRow<ContentType: View>: View {

    let label: String
    let content: () -> ContentType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).bold()
            Spacer()
            content()
        }
    }
}

struct SpecsView_Previews: PreviewProvider {
    static var previews: some View {
        SpecsView(title: "Specs", items: [
            .date(Date(), label: "Today"),
            .currency(100, code: "EUR", label: "Currency"),
            .duration(600, label: "Duration"),
            .list(["Element 1", "Element 2"], label: "List")
        ])

        SpecsView(title: "Specs", items: [
            .date(Date().addingTimeInterval(10000), label: "Today"),
            .currency(100, code: "EUR", label: "Currency"),
            .duration(600, label: "Duration"),
            .list(["Element 1", "Element 2"], label: "List")
        ])
    }
}
