//
//  StartView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/08/2023.
//

import SwiftUI

struct StartView: View {

    let colors: [Color] = [
        .accentColor,
        .secondaryAccentColor,
        .tertiaryAccentColor
    ]

    let colorsDuration: TimeInterval = 1

    @State private var opacity: CGFloat = 0
    @State private var textColorIndex = 0

    let onPresented: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image("Icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)

            TimelineView(.periodic(from: .now, by: colorsDuration)) { context in
                Text("Moviebook".uppercased())
                    .font(.hero)
                    .foregroundColor(colors[Int(context.date.timeIntervalSince1970) % colors.count])
                    .animation(.linear(duration: colorsDuration))
            }
        }
        .opacity(opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .onAppear {
            withAnimation(.linear(duration: 0.4)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onPresented()
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView() {}
    }
}
