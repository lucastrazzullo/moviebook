//
//  SpecsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/04/2023.
//

import SwiftUI

struct SpecsView: View {

    enum Item {
        case date(_ date: Date, label: String)
        case currency(_ value: Int, code: String, label: String)
        case duration(_ duration: TimeInterval, label: String)
        case list(_ elements: [String], label: String)
        case button(_ buttonAction: () -> Void, buttonLabel: String, label: String)
    }

    private enum DisplayedItem {
        case divider
        case item(Item)
    }

    private let title: String
    private let icon: String?
    private let items: [DisplayedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                if let icon {
                    Image(systemName: icon)
                }

                Text(title)
            }
            .font(.title2)
            .padding(.leading)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(zip(items.indices, items)), id: \.0) { index, item in
                    switch item {
                    case .divider:
                        Divider().id("divider\(index)")
                    case .item(let item):
                        switch item {
                        case .date(let date, let label):
                            SpecsRow(label: label) {
                                Group {
                                    if date > Date.now {
                                        Text("Coming on \(date.formatted(.dateTime.day().month().year()))")
                                            .bold()
                                            .padding(4)
                                            .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                                            .foregroundColor(.black)
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
                                Text(Duration.seconds(duration)
                                    .formatted(.units(
                                        allowed: [.weeks, .days, .hours, .minutes, .seconds, .milliseconds],
                                        width: .wide
                                    )))
                            }
                        case .list(let elements, let label):
                            SpecsRow(label: label) {
                                VStack(alignment: .trailing) {
                                    ForEach(elements, id: \.self) { element in
                                        Text(element)
                                    }
                                }
                            }
                        case .button(let action, let buttonLabel, let label):
                            SpecsRow(label: label) {
                                Button(action: action, label: { Text(buttonLabel) })
                            }
                        }
                    }
                }
            }
            .font(.subheadline)
            .padding()
        }
    }

    init(title: String, icon: String? = nil, items: [Item], showDividers: Bool = true) {
        self.title = title
        self.icon = icon
        self.items = items.enumerated()
            .reduce([DisplayedItem]()) { list, item in
                var list = list
                if showDividers, item.offset > 0 {
                    list.append(.divider)
                }
                list.append(.item(item.element))
                return list
            }
    }
}

private struct SpecsRow<ContentType: View>: View {

    let label: String
    @ViewBuilder let content: () -> ContentType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()

            content()
                .font(.callout)
                .bold()
        }
    }
}

struct SpecsView_Previews: PreviewProvider {
    static var previews: some View {
        SpecsView(title: "Info", items: [
            .date(Date().addingTimeInterval(10000), label: "Tomorrow"),
            .date(Date(), label: "Today"),
            .currency(100, code: "EUR", label: "Currency"),
            .duration(600, label: "Duration"),
            .list(["Element 1", "Element 2"], label: "List"),
            .button({}, buttonLabel: "Action", label: "Button")
        ])
    }
}
