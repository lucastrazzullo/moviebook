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

struct ScrollViewContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct ObservableScrollContent: Equatable {
    static let zero = ObservableScrollContent(offset: 0, height: 0)

    var offset: CGFloat
    var height: CGFloat
}

struct ObservableScrollView<Content>: View where Content : View {

    @Namespace var scrollSpace
    @Binding var scrollContent: ObservableScrollContent

    let content: (ScrollViewProxy) -> Content
    let showsIndicators: Bool

    init(scrollContent: Binding<ObservableScrollContent>, showsIndicators: Bool = true, @ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {
        _scrollContent = scrollContent
        self.content = content
        self.showsIndicators = showsIndicators
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            ScrollViewReader { proxy in
                content(proxy).background(GeometryReader { geometry in
                    let offset = -geometry.frame(in: .named(scrollSpace)).minY
                    let height = geometry.size.height
                    Color.clear
                        .preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                        .preference(key: ScrollViewContentHeightPreferenceKey.self, value: height)
                })
            }
        }
        .coordinateSpace(name: scrollSpace)
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            scrollContent.offset = value
        }
        .onPreferenceChange(ScrollViewContentHeightPreferenceKey.self) { value in
            scrollContent.height = value
        }
    }
}
