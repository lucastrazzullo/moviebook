//
//  PagedHorizontalGridView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/07/2023.
//

import SwiftUI

struct PagedHorizontalGridView<Item: Identifiable & Hashable, ItemView: View>: View {

    @State private var screenWidth: CGFloat = 0
    @State private var contentSize: CGSize = .zero

    @State private var offset: CGFloat = 0
    @State private var page: Int = 0

    let items: [Item]
    let spacing: CGFloat
    let pageWidth: CGFloat
    let rows: Int

    @ViewBuilder let itemView: (Item) -> ItemView

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                let columns = Int(ceil(Double(items.count / rows)))
                ForEach(0..<columns, id: \.self) { column in
                    VStack(alignment: .leading, spacing: spacing) {
                        ForEach(column*rows..<column*rows+rows, id: \.self) { index in
                            if items.indices.contains(index) {
                                let item = items[index]
                                itemView(item)
                                    .id(item.id)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, spacing)
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        contentSize = geometry.size
                    }
                }
            )
            .offset(x: offset)
            .onAppear {
                screenWidth = geometry.frame(in: .local).width
            }
        }
        .background(Color.black.opacity(0.00001))
        .frame(height: contentSize.height)
        .simultaneousGesture(
            DragGesture()
                .onChanged { gesture in
                    offset = currentScrollOffset + gesture.translation.width
                }
                .onEnded { gesture in
                    if gesture.predictedEndTranslation.width > pageWidth / 3 {
                        page = max(0, page - 1)
                    } else if gesture.predictedEndTranslation.width < -pageWidth / 3 {
                        page = min(numberOfPages - 1, page + 1)
                    }

                    let distance = abs(gesture.predictedEndTranslation.width - gesture.translation.width)
                    let duration = max(0.2, 0.8 - distance / 400)

                    withAnimation(.easeOut(duration: duration)) {
                        offset = currentScrollOffset
                    }
                }
        )
    }

    init(items: [Item],
         spacing: CGFloat,
         pageWidth: CGFloat,
         rows: Int,
         itemView: @escaping (Item) -> ItemView) {
        self.items = items
        self.spacing = spacing
        self.pageWidth = pageWidth
        self.rows = min(rows, items.count)
        self.itemView = itemView
    }

    // MARK: Private helper methods

    private var numberOfPages: Int {
        return Int(ceil(Float(contentSize.width / pageWidth)))
    }

    private var currentScrollOffset: CGFloat {
        let scrollOffset = -(CGFloat(page) * (pageWidth + spacing))
        return max(scrollOffset, screenWidth - contentSize.width)
    }
}

struct PagedScrollView_Previews: PreviewProvider {

    struct Item: Identifiable, Hashable {
        var id: Int {
            return value
        }
        let value: Int
    }

    static var previews: some View {
        PagedHorizontalGridView(
            items: (0...12).map(Item.init(value:)),
            spacing: 12,
            pageWidth: 280,
            rows: 2) { item in
                Text("\(item.value)")
                    .padding()
                    .frame(width: 280)
                    .background(.red)
            }
    }
}
