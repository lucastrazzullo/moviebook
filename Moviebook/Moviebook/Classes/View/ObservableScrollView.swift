//
//  ObservableScrollView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct ObservableScrollView<Content>: View where Content : View {
    @Namespace var scrollSpace
    @Binding var scrollOffset: CGFloat

    let content: (ScrollViewProxy) -> Content
    let showsIndicators: Bool

    init(scrollOffset: Binding<CGFloat>, showsIndicators: Bool = true, @ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {
        _scrollOffset = scrollOffset
        self.content = content
        self.showsIndicators = showsIndicators
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            ScrollViewReader { proxy in
                content(proxy).background(GeometryReader { geometry in
                    let offset = -geometry.frame(in: .named(scrollSpace)).minY
                    Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                })
            }
        }
        .coordinateSpace(name: scrollSpace)
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}
