//
//  StickyHeader.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/07/2023.
//

import SwiftUI

struct StickyHeader: ViewModifier {

    enum CurrentState: Equatable {
        case idle
        case sticking(offset: CGFloat)

        var backgroundOpacity: CGFloat {
            switch self {
            case .idle:
                return 0
            case .sticking:
                return 1
            }
        }

        var yOffset: CGFloat {
            switch self {
            case .idle:
                return 0
            case .sticking(let offset):
                return -offset
            }
        }
    }

    private let coordinateSpaceName: String

    @State private var state: CurrentState = .idle

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .padding(.vertical)
                .background(Material.regularMaterial.opacity(state.backgroundOpacity))

            Divider().opacity(state.backgroundOpacity)
        }
        .offset(y: state.yOffset)
        .zIndex(1)
        .overlay {
            GeometryReader { geometry in
                let frame = geometry.frame(in: .named(coordinateSpaceName))
                let state = frame.minY < 0
                    ? CurrentState.sticking(offset: frame.origin.y)
                    : CurrentState.idle
                Color.clear
                    .onAppear { self.state = state }
                    .onChange(of: state) { self.state = $0 }
            }
        }
    }

    init(coordinateSpaceName: String) {
        self.coordinateSpaceName = coordinateSpaceName
    }
}

extension View {

    func stickingToTop(coordinateSpaceName: String) -> some View {
        self.modifier(StickyHeader(coordinateSpaceName: coordinateSpaceName))
    }
}
